<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Verification Code - Janji Chat</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 50%, #f1f5f9 100%);
            margin: 0;
            padding: 40px 20px;
        }
        .container {
            max-width: 480px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.9);
            border-radius: 24px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(139, 92, 246, 0.15);
            border: 1px solid rgba(255, 255, 255, 0.5);
        }
        .logo {
            text-align: center;
            margin-bottom: 32px;
        }
        .logo-icon {
            width: 60px;
            height: 60px;
            background: linear-gradient(135deg, #8b5cf6 0%, #06b6d4 100%);
            border-radius: 16px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            margin-bottom: 12px;
        }
        .logo-text {
            font-size: 28px;
            font-weight: 700;
            background: linear-gradient(135deg, #8b5cf6 0%, #06b6d4 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        h1 {
            color: #1e293b;
            font-size: 24px;
            font-weight: 600;
            margin: 0 0 16px 0;
            text-align: center;
        }
        .greeting {
            color: #475569;
            font-size: 16px;
            line-height: 1.6;
            text-align: center;
            margin-bottom: 32px;
        }
        .code-box {
            background: linear-gradient(135deg, #8b5cf6 0%, #06b6d4 100%);
            border-radius: 16px;
            padding: 24px;
            text-align: center;
            margin-bottom: 24px;
        }
        .code-label {
            color: rgba(255, 255, 255, 0.8);
            font-size: 14px;
            margin-bottom: 8px;
        }
        .code {
            font-size: 42px;
            font-weight: 700;
            color: white;
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
        }
        .expires {
            color: #64748b;
            font-size: 14px;
            text-align: center;
            margin-bottom: 24px;
        }
        .expires strong {
            color: #f43f5e;
        }
        .footer {
            text-align: center;
            color: #94a3b8;
            font-size: 13px;
            padding-top: 24px;
            border-top: 1px solid #e2e8f0;
        }
        .ignore-note {
            color: #94a3b8;
            font-size: 13px;
            text-align: center;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">
            <div class="logo-icon">🍽️</div>
            <div class="logo-text">Janji Chat</div>
        </div>
        
        <h1>Verify Your Email</h1>
        
        <p class="greeting">
            Hi {{ $name }},<br>
            Please use the verification code below to complete your registration.
        </p>
        
        <div class="code-box">
            <div class="code-label">Your verification code is</div>
            <div class="code">{{ $code }}</div>
        </div>
        
        <p class="expires">
            This code will expire in <strong>10 minutes</strong>.
        </p>
        
        <p class="ignore-note">
            If you didn't request this code, you can safely ignore this email.
        </p>
        
        <div class="footer">
            © {{ date('Y') }} Janji Chat. All rights reserved.
        </div>
    </div>
</body>
</html>
