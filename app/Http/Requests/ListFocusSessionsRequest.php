<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ListFocusSessionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'visitor_id' => [
                'nullable',
                'uuid',
            ],

            'mode' => [
                'nullable',
                'string',
                Rule::in([
                    'focus',
                    'relax',
                ]),
            ],

            'status' => [
                'nullable',
                'string',
                Rule::in([
                    'active',
                    'paused',
                    'completed',
                    'cancelled',
                ]),
            ],

            'per_page' => [
                'nullable',
                'integer',
                'min:1',
                'max:100',
            ],

            'page' => [
                'nullable',
                'integer',
                'min:1',
            ],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'visitor_id' => $this->header('X-Visitor-Id'),
        ]);
    }

    public function messages(): array
    {
        return [
            'visitor_id.required' => 'The X-Visitor-Id header is required.',
            'visitor_id.uuid' => 'The X-Visitor-Id header must be a valid UUID.',
        ];
    }
}
