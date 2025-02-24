#!/usr/bin/env python3
# pylint: disable=invalid-name
"""
Module for extract password.s hash from freeipa entry and 
comare hash with wordlist hashes. 
"""

import base64
import logging
import re
import sys
import hashlib
import secrets

logging.basicConfig(level=logging.INFO)

def hash_password(password, pwd_type, pw_salt=None, iterations_cnt=260000):
    """Get password hash"""
    if pw_salt is None:
        pw_salt = secrets.token_hex(16)
    pw_hash = hashlib.pbkdf2_hmac(
        pwd_type, password.encode("utf-8"), pw_salt, iterations_cnt
    )
    encoded_pw_hash = ''
    encoded_salt = ''
    if pwd_type == 'sha256':
        encoded_pw_hash = base64.b64encode(
            pw_hash, altchars=b'./').decode('utf-8')
        encoded_salt = base64.b64encode(
            pw_salt, altchars=b'./').decode('utf-8')
    elif pwd_type == 'sha512':
        encoded_pw_hash = base64.b64encode(pw_hash).decode('utf-8')
        encoded_salt = base64.b64encode(pw_salt).decode('utf-8')

    encoded_pw_hash = encoded_pw_hash.rstrip('=')
    encoded_salt = encoded_salt.rstrip('=')
    return f"pbkdf2_{pwd_type}${iterations_cnt}${encoded_salt}${encoded_pw_hash}"


def verify_password(password, pwd_type, original_pw_salt, password_hash):
    """Check password string with hash"""
    if (password_hash or "").count("$") != 3 or not pw_type:
        return False
    _, iterations_cnt, _, _ = password_hash.split("$", 3)
    iterations_cnt = int(iterations_cnt)
    compare_hash = hash_password(
        password, pwd_type, original_pw_salt, iterations_cnt)
    # print(f"! {word} {compare_hash} {password_hash}")
    return secrets.compare_digest(password_hash, compare_hash)

wordlist = []
iteration = 1
try:
    with open('wordlist', encoding='utf-8') as f:
        wordlist = f.readlines()
except FileNotFoundError:
    print("File wordlist does not exist.")
    wordlist = ['userpassword']
except:  # pylint: disable=bare-except
    exit(1)

# pylint: disable=invalid-name
next_line = False
# pylint: disable=invalid-name
user = ''
# pylint: disable=invalid-name
nt_hash = ''
# pylint: disable=invalid-name
complete_user = False

for line in sys.stdin:
    line = line.strip()

    m = re.match(r'^\s+id [0-9]+$', line)
    if m:
        user = ''
        nt_hash = ''

    if not user:
        m = re.match(r'^\s*uid: (.*)$', line)
        if m:
            user = m.group(1)
            encoded_hash = ''

    # Extract password hash
    m = re.match(r'userPassword:: ([a-z0-9\+/=]+)', line, re.IGNORECASE)
    if m:
        encoded_hash = m.group(1)
        next_line = True

    # Hash is usually split across multiple lines
    elif next_line:
        m = re.match(r'^\s*([a-z0-9\+/=]+)$', line, re.IGNORECASE)
        if m:
            encoded_hash += m.group(1).strip()
        else:
            next_line = False
            complete_user = True
    original_salt = None
    if complete_user:
        decoded_hash = base64.b64decode(encoded_hash).decode('utf-8')
        pw_type = ''
        if '{PBKDF2_SHA256}' in decoded_hash:
            pw_type = 'sha256'
            binary_hash = base64.b64decode(decoded_hash[15:])
            iterations = int.from_bytes(binary_hash[0:4], byteorder='big')

            # John uses a slightly different base64 encodeding, with + replaced by .
            original_salt = binary_hash[4:68]
            salt = base64.b64encode(
                original_salt, altchars=b'./').decode('utf-8').rstrip('=')
            # 389-ds specifies an ouput (dkLen) length of 256 bytes,
            # which is longer than John supports
            # However, we can truncate this to 32 bytes and crack those
            b64_hash = base64.b64encode(
                binary_hash[68:], altchars=b'./').decode('utf-8').rstrip('=')

            # Formatted for John
            decoded_hash = f"pbkdf2_{pw_type}${iterations}${salt}${b64_hash}"
        elif '{PBKDF2-SHA512}' in decoded_hash:
            # pw_type = '' # Now it unsupported
            pw_type = 'sha512'
            extracted_hash = decoded_hash[15:].split("$")
            iterations = extracted_hash[0]
            salt = extracted_hash[1].rstrip('=')
            original_salt = base64.b64decode(salt)
            b64_hash = extracted_hash[2].rstrip('=')

            # for rchar in ['.', '/']:
            #     salt = salt.replace(rchar, '+')
            #     b64_hash = b64_hash.replace(rchar, '+')
            decoded_hash = f"pbkdf2_{pw_type}${iterations}${salt}${b64_hash}"

        logging.info("[%d] Check passwords for user %s", iteration, user)
        for word in [user] + wordlist:
            if verify_password(word.strip(), pw_type, original_salt, decoded_hash):
                logging.warning("User %s has password %s !",
                                user, word.strip())
                print(f'{user}:{word.strip()}')
                break
        # print(f'{user}:{decoded_hash}')
        complete_user = False
        user = ''
        nt_hash = ''
        iteration = iteration + 1
