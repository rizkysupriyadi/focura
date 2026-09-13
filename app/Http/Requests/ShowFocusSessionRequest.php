<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ShowFocusSessionRequest extends FormRequest
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
'visitor_id' => [
    'nullable',
    'uuid',
],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'visitor_id' => $this->header('X-Visitor-Id'),
        ]);
    }

    /**
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
