<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Welcome to Janji Chat</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 32px;
            margin-bottom: 10px;
        }
        h1 {
            color: #1a1a1a;
            font-size: 24px;
            margin: 0 0 10px;
        }
        .subtitle {
            color: #666;
            font-size: 16px;
        }
        .credentials-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 8px;
            padding: 25px;
            margin: 25px 0;
        }
        .credentials-box h3 {
            margin: 0 0 15px;
            font-size: 18px;
        }
        .credential-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid rgba(255,255,255,0.2);
        }
        .credential-item:last-child {
            border-bottom: none;
        }
        .credential-label {
            opacity: 0.9;
        }
        .credential-value {
            font-weight: bold;
            font-family: monospace;
            background: rgba(255,255,255,0.2);
            padding: 2px 8px;
            border-radius: 4px;
        }
        .verify-button {
            display: block;
            text-align: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white !important;
            text-decoration: none;
            padding: 16px 32px;
            border-radius: 8px;
            font-weight: bold;
            font-size: 16px;
            margin: 30px 0;
        }
        .verify-button:hover {
            opacity: 0.9;
        }
        .info-text {
            color: #666;
            font-size: 14px;
            margin-top: 20px;
        }
        .warning-text {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 6px;
            padding: 12px;
            font-size: 14px;
            color: #856404;
            margin-top: 20px;
        }
        .footer {
            text-align: center;
            color: #999;
            font-size: 12px;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🍽️ 📦</div>
            <h1>Welcome to Janji Chat!</h1>
            <p class="subtitle">Your merchant account has been created</p>
        </div>

        <p>Hello <strong>{{ $user->name }}</strong>,</p>
        
        <p>Your Janji Chat merchant account has been created by the administrator. Below are your login credentials:</p>

        <div class="credentials-box">
            <h3>🔐 Your Login Credentials</h3>
            <div class="credential-item">
                <span class="credential-label">Email:</span>
                <span class="credential-value">{{ $user->email }}</span>
            </div>
            <div class="credential-item">
                <span class="credential-label">Password:</span>
                <span class="credential-value">{{ $plainPassword }}</span>
            </div>
            <div class="credential-item">
                <span class="credential-label">Business Type:</span>
                <span class="credential-value">{{ ucfirst(str_replace('_', ' ', $user->business_type)) }}</span>
            </div>
        </div>

        <p>To activate your account and start using Janji Chat, please click the button below to verify your email address:</p>

        <a href="{{ $verificationUrl }}" class="verify-button">
            ✉️ Verify Email & Sign In
        </a>

        <div class="warning-text">
            ⚠️ <strong>Important:</strong> This verification link will expire in 7 days. After verification, we recommend changing your password for security.
        </div>

        <p class="info-text">
            If you did not expect this email or believe this was sent in error, please contact the administrator.
        </p>

        <div class="footer">
            <p>&copy; {{ date('Y') }} Janji Chat. All rights reserved.</p>
            <p>This is an automated email. Please do not reply.</p>
        </div>
    </div>
</body>
</html>
