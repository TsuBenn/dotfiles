import subprocess
import os
import getpass

def verify_user_credentials(password_text):
    try:
        # Get the username of the current unprivileged session
        username = getpass.getuser()
        
        # Format the stdin buffer: <username>\0<password>\0
        input_buffer = f"{username}\x00{password_text}\x00".encode('utf-8')
        
        # Argument 1: The binary path
        # Argument 2: The service type (use 'chkpwd' or your own custom lock name)
        # Argument 3: Options (nonroot tells it you are a normal user account)
        process = subprocess.run(
            ['/sbin/unix_chkpwd', 'chkpwd', 'nonroot'],
            input=input_buffer,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Real system results mapping:
        # 0 = Password Correct
        # 7 = Authentication Failure (Wrong Password)
        if process.returncode == 0:
            return "✅ Authorized"
        elif process.returncode == 7:
            return "❌ Access Denied: Wrong Password"
        else:
            return f"⚠️ System Error: Code {process.returncode}"
            
    except Exception as e:
        return f"Error: {str(e)}"

# Test with a bad password to make sure it rejects it!
print(verify_user_credentials("tsubenn"))

