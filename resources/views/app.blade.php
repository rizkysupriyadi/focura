<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="UTF-8">
        <meta
            name="viewport"
            content="width=device-width, initial-scale=1.0"
        >

        <meta
            name="description"
            content="Focura — a simple workspace to protect your attention, track interruptions, and understand your focus."
        >

        <meta
            name="theme-color"
            content="#2563eb"
        >

        <meta
            name="csrf-token"
            content="{{ csrf_token() }}"
        >

        <meta
            name="mobile-web-app-capable"
            content="yes"
        >

        <meta
            name="apple-mobile-web-app-capable"
            content="yes"
        >

        <meta
            name="apple-mobile-web-app-status-bar-style"
            content="default"
        >

        <meta
            name="apple-mobile-web-app-title"
            content="Focura"
        >

        <link
            rel="manifest"
            href="/manifest.webmanifest"
        >

        <link
            rel="icon"
            href="/favicon.svg"
            type="image/svg+xml"
        >

        <link
            rel="apple-touch-icon"
            href="/apple-touch-icon.png"
        >

        <title>Focura — Focus with intention.</title>

        @vite(['resources/css/app.css', 'resources/js/app.ts'])
    </head>

    <body>
        <div id="app"></div>
    </body>
</html>
