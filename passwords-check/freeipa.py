#!/usr/bin/env python3
# pylint: disable=invalid-name
"""
Module for extract password.s hash from freeipa entry and
comare hash with wordlist hashes.
"""

import base64
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import secrets
import os
import datetime
import time
import ldap
import ldap.asyncsearch

logging.basicConfig(level=logging.INFO)


class IPAPasswordChecker:
    """
    Sync gitlab users/groups with freeipa ldap
    """

    def __init__(self):
        ldap_url_env = os.getenv('LDAP_URL')
        self.ldap_url = ldap_url_env if ldap_url_env else ''
        ldap_users_base_dn_env = os.getenv('LDAP_USERS_BASE_DN')
        self.ldap_users_base_dn = ldap_users_base_dn_env if ldap_users_base_dn_env else ''
        ldap_bind_dn_env = os.getenv('LDAP_BIND_DN')
        self.ldap_bind_dn = ldap_bind_dn_env if ldap_bind_dn_env else ''
        ldap_password_env = os.getenv('LDAP_PASSWORD')
        self.ldap_password = ldap_password_env if ldap_password_env else ''
        ldap_filter_env = os.getenv('LDAP_FILTER')
        self.ldap_filter = ldap_filter_env if ldap_filter_env else ''
        ldap_passwords_file_env = os.getenv('LDAP_PASSWORDS_FILE')
        self.ldap_passwords_file = \
            ldap_passwords_file_env if ldap_passwords_file_env else 'wordlist'

        self.wordlist = []

        logging.info("Loading file %s", self.ldap_passwords_file)
        try:
            with open(self.ldap_passwords_file, encoding='utf-8') as f:
                self.wordlist = f.readlines()
        except FileNotFoundError:
            logging.warning(
                "File %s does not exist. Fallback to one default password.",
                self.ldap_passwords_file)
            self.wordlist = ['userpassword']
        except:  # pylint: disable=bare-except
            exit(1)

        # pylint: disable=invalid-name
        self.ldap_obj = None
        # Check only account which password expired somethere in the future
        date_expiration = datetime.datetime.now()  # - datetime.timedelta(weeks=1)
        password_expiration_border_date = date_expiration.strftime(
            "%Y%m%d%H%M%SZ")
        # pylint: disable=line-too-long
        self.user_filter = f"(&(!(nsaccountlock=TRUE))(krbPasswordExpiration>={password_expiration_border_date}))"  # nopep8
        if self.ldap_filter:
            self.user_filter = f"(&({self.ldap_filter})(!(nsaccountlock=TRUE)))"  # nopep8

        logging.info('Initialize freeipa password checker')

    def hash_password(self, password, pwd_type, pw_salt=None, iterations_cnt=260000):
        """Get password hash"""
        if pw_salt is None:
            pw_salt = secrets.token_hex(16)
        # logging.info(f"! {password} {pwd_type} {pw_salt} {iterations_cnt}")
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

    def verify_password(self, password, pwd_type, original_pw_salt, password_hash):
        """Check password string with hash"""
        if (password_hash or "").count("$") != 3 or not pwd_type:
            return False
        _, iterations_cnt, _, _ = password_hash.split("$", 3)
        iterations_cnt = int(iterations_cnt)
        # logging.info(f"!! {password} {pwd_type} {original_pw_salt} {password_hash}")
        compare_hash = self.hash_password(
            password, pwd_type, original_pw_salt, iterations_cnt)
        return secrets.compare_digest(password_hash, compare_hash)

    def bind_to_ldap(self):
        """
        Bind to LDAP
        """
        logging.info('Connecting to LDAP')
        if not self.ldap_url:
            logging.error('You should configure LDAP URL')
            return 1

        try:
            self.ldap_obj = ldap.initialize(uri=self.ldap_url)
            self.ldap_obj.simple_bind_s(self.ldap_bind_dn,
                                        self.ldap_password)
        except Exception as expt:  # pylint: disable=bare-except,broad-exception-caught
            logging.error('Error while connecting to ldap')
            logging.error(expt)
            return 1
        if self.ldap_obj is None:
            logging.error('Cannot create ldap object, aborting')
            return 1
        return 0

    def check_password(self, username, passwd):
        """
        Check password for current user and return it
        """
        logging.info("Check passwords for user %s", username)
        start_time = time.time()
        pw_type = ''
        decoded_hash = ''
        original_salt = None
        iterations = 0
        if '{PBKDF2_SHA256}' in passwd:
            pw_type = 'sha256'
            binary_hash = base64.b64decode(passwd[15:])
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
        elif '{PBKDF2-SHA512}' in passwd:
            # pw_type = '' # Now it unsupported
            pw_type = 'sha512'
            extracted_hash = passwd[15:].split("$")
            iterations = extracted_hash[0]
            salt = extracted_hash[1].rstrip('=')
            original_salt = base64.b64decode(salt)
            b64_hash = extracted_hash[2].rstrip('=')

            # for rchar in ['.', '/']:
            #     salt = salt.replace(rchar, '+')
            #     b64_hash = b64_hash.replace(rchar, '+')
            decoded_hash = f"pbkdf2_{pw_type}${iterations}${salt}${b64_hash}"

        for word in [username] + self.wordlist:
            if self.verify_password(word.strip(), pw_type, original_salt, decoded_hash):
                elapsed_time = time.time() - start_time
                logging.warning("User %s has password %s ! Time: %f",
                            username,  word.strip(), elapsed_time)
                return {
                    'username': username,
                    'password': word.strip()
                }
        elapsed_time = time.time() - start_time
        logging.info("Check passwords for user %s done, time %f", username, elapsed_time)
        return None

    def check_users(self):
        """
        Search users in LDAP using filter and check passwords
        """
        user_list = []
        # pylint: disable=invalid-name
        for _, user in self.ldap_obj.search_s(base=self.ldap_users_base_dn,
                                              scope=ldap.SCOPE_SUBTREE,
                                              filterstr=self.user_filter,
                                              attrlist=['uid',
                                                        'userPassword']):
            if 'uid' in user:
                username = user['uid'][0].decode('utf-8')
                passwd = user['userPassword'][0].decode('utf-8')
                # logging.info("%s - %s", username, passwd)
                user_list.append({
                    'username': username,
                    'password': passwd
                })

        detected_users = []

        # FIXME: get dynamic workers count
        with ThreadPoolExecutor(max_workers=4) as executor:
            # Schedule the API calls with different users
            futures = [
                executor.submit(
                    self.check_password, u['username'], u['password']
                ) for u in user_list
            ]

            # Use as_completed to wait for all threads to complete
            for future in as_completed(futures):
                try:
                    res = future.result()
                    if res:
                        detected_users.append(res)
                except Exception as e:  # pylint: disable=bare-except,broad-exception-caught
                    logging.error(
                        "Error occured during the execution of check password %s", e
                    )

        for u in detected_users:
            print(f"{u['username']} {u['password']}")

    def check(self):
        """Check users passwords"""
        try:
            is_not_connected = 0
            is_not_connected += self.bind_to_ldap()
            if is_not_connected > 0:
                logging.error("Cannot connect, exit class")
                return
            self.check_users()
        except Exception as expt:  # pylint: disable=broad-exception-caught
            logging.error("Received exception %s", expt)
            return

if __name__ == "__main__":
    checker = IPAPasswordChecker()
    checker.check()
