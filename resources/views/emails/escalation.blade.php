<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Customer Needs Attention</title>
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
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
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

        .alert-box {
            background: linear-gradient(135deg, #f59e0b 0%, #ef4444 100%);
            color: white;
            border-radius: 8px;
            padding: 20px;
            margin: 25px 0;
        }

        .alert-box h3 {
            margin: 0 0 10px;
            font-size: 16px;
        }

        .alert-box p {
            margin: 0;
            opacity: 0.95;
        }

        .info-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }

        .info-item {
            padding: 8px 0;
            border-bottom: 1px solid #e2e8f0;
        }

        .info-item:last-child {
            border-bottom: none;
        }

        .info-label {
            color: #64748b;
            font-size: 14px;
        }

        .info-value {
            font-weight: 600;
            color: #1e293b;
        }

        .messages-section {
            margin: 25px 0;
        }

        .messages-title {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e2e8f0;
        }

        .chat-container {
            background: #f1f5f9;
            border-radius: 12px;
            padding: 15px;
        }

        .message-table {
            width: 100%;
            max-width: 750px;
            border-collapse: collapse;
            margin: 0 auto;
        }

        .message-row {
            margin-bottom: 12px;
        }

        .message-bubble {
            padding: 10px 14px;
            border-radius: 16px;
            font-size: 14px;
            display: inline-block;
            max-width: 85%;
        }

        .message-bubble-customer {
            background: #3b82f6;
            color: white;
            border-bottom-left-radius: 4px;
        }

        .message-bubble-ai {
            background: #22c55e;
            color: white;
            border-bottom-right-radius: 4px;
        }

        .message-bubble-admin {
            background: #8b5cf6;
            color: white;
            border-bottom-right-radius: 4px;
        }

        .message-meta {
            font-size: 11px;
            opacity: 0.8;
            margin-bottom: 4px;
        }

        .message-content {
            white-space: pre-wrap;
            word-break: break-word;
        }

        .action-button {
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

        .action-button:hover {
            opacity: 0.9;
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
            <div class="logo">⚠️</div>
            <h1>Customer Needs Your Attention</h1>
            <p class="subtitle">A conversation has been escalated</p>
        </div>

        <div class="alert-box">
            <h3>📋 Escalation Reason</h3>
            <p>{{ $reason }}</p>
        </div>

        <div class="info-box">
            <div class="info-item">
                <span class="info-label">Customer Name- &nbsp;</span>
                <span class="info-value">{{ $customerName }}</span>
            </div>
            <div class="info-item">
                <span class="info-label">Phone Number- &nbsp;</span>
                <span class="info-value">{{ $customerPhone }}</span>
            </div>
        </div>

        <div class="messages-section">
            <div class="messages-title">💬 Last {{ count($messages) }} Messages</div>

            <div class="chat-container">
                <table class="message-table" cellpadding="0" cellspacing="0">
                    @foreach ($messages as $message)
                        @if ($message['direction'] === 'inbound')
                            {{-- Customer message - LEFT side --}}
                            <tr>
                                <td align="left" style="padding: 6px 0;">
                                    <div class="message-bubble message-bubble-customer">
                                        <div class="message-meta">🧑 Customer • {{ $message['created_at'] }}</div>
                                        <div class="message-content">{{ $message['content'] }}</div>
                                    </div>
                                </td>
                            </tr>
                        @else
                            {{-- AI/Admin message - RIGHT side --}}
                            <tr>
                                <td align="right" style="padding: 6px 0;">
                                    <div
                                        class="message-bubble {{ $message['sender_type'] === 'ai' ? 'message-bubble-ai' : 'message-bubble-admin' }}">
                                        <div class="message-meta">
                                            {{ $message['sender_type'] === 'ai' ? '🤖 AI' : '👤 Admin' }} •
                                            {{ $message['created_at'] }}
                                        </div>
                                        <div class="message-content">{{ $message['content'] }}</div>
                                    </div>
                                </td>
                            </tr>
                        @endif
                    @endforeach
                </table>
            </div>
        </div>

        <a href="{{ $conversationUrl }}" class="action-button">
            💬 View Conversation & Reply
        </a>

        <div class="footer">
            <p>&copy; {{ date('Y') }} Janji Chat. All rights reserved.</p>
            <p>This is an automated notification. Please respond via the dashboard.</p>
        </div>
    </div>
</body>

</html>
