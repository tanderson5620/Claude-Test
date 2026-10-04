"""Embed bake.py output into donut-town-vr.html as <script id="rimshot-data" type="application/json">.

  python embed.py bake_out ../../donut-town-vr.html

Textures become JPEG data URIs (normals q92, AO q85 greyscale); fine skin pores are mixed into the
head normal map here because they are finer than the sculpt resolution. The block replaces whatever
sits between the RIMSHOT-DATA markers, so re-running is safe.
"""
import base64, io, json, os, re, sys
import numpy as np
from PIL import Image

src, html_path = sys.argv[1], sys.argv[2]
rng = np.random.default_rng(77)

def add_pores(img):
    n = np.asarray(img, np.float32) / 127.5 - 1
    h, w = n.shape[:2]
    H = np.zeros((h, w), np.float32)
    ys, xs = rng.integers(0, h, 40000), rng.integers(0, w, 40000)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            np.add.at(H, ((ys + dy) % h, (xs + dx) % w), -np.exp(-(dx * dx + dy * dy) / 1.4) * rng.uniform(0.5, 1, len(ys)))
    gx = (np.roll(H, 1, 1) - np.roll(H, -1, 1)) * 0.35
    gy = (np.roll(H, -1, 0) - np.roll(H, 1, 0)) * 0.35
    n[..., 0] += gx; n[..., 1] += gy
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(np.clip((n + 1) * 127.5, 0, 255).astype(np.uint8))

def data_uri(img, q):
    b = io.BytesIO(); img.save(b, 'JPEG', quality=q, optimize=True)
    return 'data:image/jpeg;base64,' + base64.b64encode(b.getvalue()).decode()

images = {}
for part in ('body', 'head', 'jersey', 'shorts', 'sleeve'):
    nrm = Image.open(os.path.join(src, part + '_nrm.png')).convert('RGB')
    if part == 'head': nrm = add_pores(nrm)
    images[part + '_nrm'] = data_uri(nrm, 92)
    images[part + '_ao'] = data_uri(Image.open(os.path.join(src, part + '_ao.png')).convert('L'), 85)
data = {'body': json.load(open(os.path.join(src, 'body.json'))),
        'bin': base64.b64encode(open(os.path.join(src, 'body.bin'), 'rb').read()).decode(),
        'images': images}
block = '<!-- RIMSHOT-DATA -->\n<script id="rimshot-data" type="application/json">' + json.dumps(data, separators=(',', ':')) + '</script>\n<!-- /RIMSHOT-DATA -->'
html = open(html_path).read()
html, k = re.subn(r'<!-- RIMSHOT-DATA -->.*?<!-- /RIMSHOT-DATA -->', lambda m: block, html, flags=re.S)
assert k == 1, 'RIMSHOT-DATA markers not found'
open(html_path, 'w').write(html)
print('embedded', len(block) // 1024, 'KB;', {k: len(v) // 1024 for k, v in images.items()})
