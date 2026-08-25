# Assets - Wallpapers

Ce dossier contient les images utilisées par `scripts/Set-Wallpaper.ps1`.

## Fichiers attendus

- `home.jpg` → Wallpaper du Bureau Windows (appliqué via `SystemParametersInfo`)
- `lock.jpg` → Wallpaper du Lock Screen (appliqué via Registre `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization` + remplacement de `C:\Windows\Web\Wallpaper\Windows\img0.jpg`)

## Format recommandé

- Format: JPG ou PNG (JPG recommandé pour compatibilité maximale)
- Résolution: 1920x1080 minimum, idéalement 2560x1440 ou 3840x2160
- Taille: < 5 MB pour éviter les lenteurs de copie

## Utilisation

1. Uploade tes images ici:
   - `assets/home.jpg`
   - `assets/lock.jpg`

2. Le workflow `chill.yml` exécute automatiquement:
   ```powershell
   .\scripts\Set-Wallpaper.ps1 -DesktopWallpaperPath "assets/home.jpg" -LockScreenImagePath "assets/lock.jpg"
   ```

3. Si un fichier est manquant, le script l'ignore silencieusement (pas d'erreur).

## Notes

- Le dossier est versionné avec `.gitkeep` pour exister même vide.
- Tu peux utiliser des chemins absolus si tu le souhaites en modifiant les paramètres du script.
- Le Lock Screen nécessite des droits administrateur (déjà le cas dans le runner GitHub Actions).
