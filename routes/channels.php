<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

/**
 * Private channel for merchant conversations.
 * Only the merchant who owns the conversation can subscribe.
 */
Broadcast::channel('conversations.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});
