<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserAddress extends Model
{
    protected $fillable = [
        'user_id',
        'label',
        'recipient_name',
        'phone_number',
        'full_address',
        'city',
        'is_default',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
