<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankAccount;
use Illuminate\Http\Request;

class BankController extends Controller
{
    public function index(Request $request)
    {
        $banks = BankAccount::where('user_id', $request->user()->id)->get();
        return response()->json(['data' => $banks]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'bank_name' => 'required|string|max:255',
            'account_number' => 'required|string|max:255',
            'account_name' => 'required|string|max:255',
        ]);

        $bank = BankAccount::create([
            'user_id' => $request->user()->id,
            'bank_name' => $request->bank_name,
            'account_number' => $request->account_number,
            'account_name' => $request->account_name,
        ]);

        return response()->json([
            'message' => 'Rekening berhasil ditambahkan',
            'data' => $bank
        ], 201);
    }

    public function destroy(Request $request, $id)
    {
        $bank = BankAccount::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();
            
        $bank->delete();

        return response()->json([
            'message' => 'Rekening berhasil dihapus'
        ]);
    }
}
