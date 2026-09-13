<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSessionInterruptionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'started_at' => [
                'required',
                'date',
            ],
            'ended_at' => [
                'required',
                'date',
                'after_or_equal:started_at',
            ],
        ];
    }
}
