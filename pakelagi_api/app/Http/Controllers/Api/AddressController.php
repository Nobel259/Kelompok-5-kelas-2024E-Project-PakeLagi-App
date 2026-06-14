<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserAddress;
use Illuminate\Http\Request;

class AddressController extends Controller
{
    public function index(Request $request)
    {
        $addresses = $request->user()->addresses()->orderBy('is_default', 'desc')->get();
        return response()->json([
            'status' => 'success',
            'data' => $addresses
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'label' => 'required|string|max:100',
            'recipient_name' => 'required|string|max:255',
            'phone_number' => 'required|string|max:20',
            'full_address' => 'required|string',
            'city' => 'nullable|string|max:100',
            'is_default' => 'nullable|boolean',
        ]);

        $user = $request->user();
        $isDefault = $request->input('is_default', false);

        if ($isDefault) {
            UserAddress::where('user_id', $user->id)->update(['is_default' => false]);
        }

        $count = UserAddress::where('user_id', $user->id)->count();
        if ($count === 0) {
            $isDefault = true;
        }

        $addressId = $request->input('id');
        if ($addressId) {
            $address = UserAddress::where('user_id', $user->id)->findOrFail($addressId);
            $address->update([
                'label' => $request->label,
                'recipient_name' => $request->recipient_name,
                'phone_number' => $request->phone_number,
                'full_address' => $request->full_address,
                'city' => $request->input('city', ''),
                'is_default' => $isDefault,
            ]);
        } else {
            $address = UserAddress::create([
                'user_id' => $user->id,
                'label' => $request->label,
                'recipient_name' => $request->recipient_name,
                'phone_number' => $request->phone_number,
                'full_address' => $request->full_address,
                'city' => $request->input('city', ''),
                'is_default' => $isDefault,
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Alamat berhasil disimpan',
            'data' => $address
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $address = UserAddress::where('user_id', $request->user()->id)->findOrFail($id);
        $address->delete();

        $remaining = UserAddress::where('user_id', $request->user()->id)->first();
        if ($remaining && $address->is_default) {
            $remaining->update(['is_default' => true]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Alamat berhasil dihapus'
        ]);
    }
}
