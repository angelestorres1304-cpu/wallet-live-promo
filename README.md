# Wallet Live Promo — versión TikTok LIVE

Panel móvil vertical para preparar y compartir códigos durante una transmisión de TikTok.

## Ejecutar

```bash
flutter pub get
flutter run
```

Para Android conectado: `flutter run -d android`. Para web: `flutter run -d chrome`.

## Uso en un LIVE

1. Abre la app y pulsa **GENERAR CÓDIGO**.
2. Define descuento, usos y duración.
3. Pulsa **COPIAR**.
4. Abre TikTok LIVE y pega el código en el chat; también puedes mostrar el panel en otro dispositivo.
5. Elimina el código cuando termine la oferta.

Los códigos se guardan localmente en el teléfono. El proyecto funciona como panel auxiliar: TikTok debe iniciarse desde su aplicación oficial y esta app no automatiza el chat ni simula espectadores.

## Publicar Android

```bash
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/release/app-release.apk`.
