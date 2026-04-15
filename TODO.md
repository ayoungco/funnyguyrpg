- [ ] Replace third-party assets pending license review with original assets created by the team
- [x] Update the README with actual information about the project instead of just advertising
- [ ] Add a license to the project
- [ ] Trim down and repackage graphics assets to be more efficient and less bloated
- [ ] Bootstrap a minimal automated semver release process to make it easier to maintain the project and keep the changelog up to date

## Web release

- [x] Download EasyRPG Player web build and place files in web/ (see docs/next/00-web-release.md step 1)
- [ ] Convert Sound/*.wav to OGG to reduce download size (ffmpeg batch convert, see docs/next/00-web-release.md)
- [x] Run scripts/build-web.sh and verify locally with python3 -m http.server 8080 --directory dist/web/
- [ ] Set up Cloudflare Pages (or Netlify) deployment from this repo pointing at dist/web/
- [x] Add COOP/COEP headers config for web host (web/_headers, web/netlify.toml)
- [x] Write build-web.sh and generate_index.py scripts
- [x] Remove developer save files from git history (Save*.lsd)
