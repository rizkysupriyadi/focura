<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreFocusSessionRequest extends FormRequest
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
        'mode' => [
            'required',
            'string',
            Rule::in([
                'focus',
                'relax',
            ]),
        ],

        'title' => [
            'nullable',
            'string',
            'max:255',
        ],

        'planned_duration_seconds' => [
            'required',
            'integer',
            'min:1',
        ],

        'started_at' => [
            'required',
            'date',
        ],

        'visitor_id' => [
            'nullable',
            'uuid',
        ],
    ];
}

    /**
     * Use the request header as the source of truth
     * for guest visitor ownership.
     */
    protected function prepareForValidation(): void
    {
        $this->merge([
            'visitor_id' => $this->header('X-Visitor-Id'),
        ]);
    }

    /**
     * Custom validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'visitor_id.required' => 'The X-Visitor-Id header is required.',
            'visitor_id.uuid' => 'The X-Visitor-Id header must be a valid UUID.',
        ];
    }
}
