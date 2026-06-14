<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Product extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'description',
        'price',
        'is_sold',
        'categories',
        'image_paths',
        'address_id',
    ];

    protected $casts = [
        'categories' => 'array',
        'image_paths' => 'array',
        'is_sold' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function address(): BelongsTo
    {
        return $this->belongsTo(UserAddress::class, 'address_id');
    }
}
