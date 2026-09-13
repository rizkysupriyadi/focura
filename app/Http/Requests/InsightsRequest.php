<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class InsightsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'range' => [
                'nullable',
                'string',
                Rule::in([
                    '7d',
                    '30d',
                    '90d',
                    'all',
                ]),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'range.in' => 'The insights range must be 7d, 30d, 90d, or all.',
        ];
    }
}
