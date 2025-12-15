<?php

return [
    /*
    |--------------------------------------------------------------------------
    | WhatsApp Phone Number ID
    |--------------------------------------------------------------------------
    |
    | The Phone Number ID from Meta's WhatsApp Business API.
    |
    */
    'phone_number_id' => env('WHATSAPP_PHONE_NUMBER_ID'),

    /*
    |--------------------------------------------------------------------------
    | WhatsApp Access Token
    |--------------------------------------------------------------------------
    |
    | The permanent access token for authenticating with WhatsApp API.
    |
    */
    'access_token' => env('WHATSAPP_ACCESS_TOKEN'),

    /*
    |--------------------------------------------------------------------------
    | Webhook Verify Token
    |--------------------------------------------------------------------------
    |
    | The token used to verify webhook requests from Meta.
    |
    */
    'verify_token' => env('WHATSAPP_VERIFY_TOKEN'),

    /*
    |--------------------------------------------------------------------------
    | API Version
    |--------------------------------------------------------------------------
    |
    | The Meta Graph API version to use.
    |
    */
    'api_version' => env('WHATSAPP_API_VERSION', 'v18.0'),

    /*
    |--------------------------------------------------------------------------
    | API Base URL
    |--------------------------------------------------------------------------
    |
    | The base URL for WhatsApp Cloud API.
    |
    */
    'api_base_url' => 'https://graph.facebook.com',

    /*
    |--------------------------------------------------------------------------
    | Test Phone Number
    |--------------------------------------------------------------------------
    |
    | The Meta-provided test phone number for development.
    |
    */
    'test_phone' => env('WHATSAPP_TEST_PHONE'),
];
