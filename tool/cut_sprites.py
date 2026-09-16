"""art/ の元絵から assets/chara/ の立ち絵と顔アイコンを切り出す。

    python tool/cut_sprites.py

元絵は1枚に4表情が横並びになっている(左から 普通・驚き・落ち込み・喜び)。
背景は透過済みなので、アルファの列ごとの合計がいちばん小さいところを
キャラの切れ目とみなして4分割している。等分すると、月の裾が隣に食い込む。

顔アイコンは、回転させても破綻しないように作ってある:
頭より少し大きい正方形の中央に頭を置き、円の外を消す。こうしておくと
自転させたときに切り出しの角や肩が現れない。
"""

import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "art")
OUT = os.path.join(ROOT, "assets", "chara")

FACES = ["normal", "surprise", "sad", "happy"]
BODY_HEIGHT = 760
ICON_SIZE = 288

# 顔アイコンに使う「全身に対する頭の高さの割合」。
# 月は冠と髪飾りがあるぶん高く取る必要がある。
HEAD_RATIO = {"sun": 0.190, "moon": 0.215, "earth": 0.175}


def load(name):
    """元絵を開いて、余白を落とした状態で返す。"""
    return Image.open(os.path.join(SRC, f"sheet_{name}.png")).convert("RGBA")


def split_columns(im):
    """4人分の左右の境界を返す。アルファが薄いところを切れ目とみなす。"""
    w = im.size[0]
    col = (np.array(im.getchannel("A")) > 20).sum(axis=0)
    cuts = [0]
    for b in (w // 4, w // 2, 3 * w // 4):
        lo, hi = max(0, b - 70), min(w, b + 70)
        cuts.append(lo + int(np.argmin(col[lo:hi])))
    cuts.append(w)
    return cuts


def cut_bodies(name, im):
    cuts = split_columns(im)
    for i, face in enumerate(FACES):
        piece = im.crop((cuts[i], 0, cuts[i + 1], im.size[1]))
        piece = piece.crop(piece.getbbox())
        w, h = piece.size
        piece = piece.resize((max(1, round(w * BODY_HEIGHT / h)), BODY_HEIGHT), Image.LANCZOS)
        piece.save(os.path.join(OUT, f"{name}_{face}.png"), optimize=True)


def cut_icon(name, im):
    piece = im.crop((0, 0, split_columns(im)[1], im.size[1]))
    piece = piece.crop(piece.getbbox())
    w, h = piece.size
    head_h = int(h * HEAD_RATIO[name])

    # 頭の中心。上のほうだけ見て、不透明な画素の重心を取る。
    top = np.array(piece.getchannel("A"))[: int(head_h * 0.55), :]
    weights = (top > 40).sum(axis=0)
    cx = int((np.arange(w) * weights).sum() / max(weights.sum(), 1))
    half = head_h // 2
    head = piece.crop((max(0, cx - half), 0, min(w, cx + half), head_h))

    side = int(head_h * 1.22)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(head, ((side - head.width) // 2, (side - head.height) // 2 + int(side * 0.02)))

    mask = Image.new("L", (side, side), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, side - 3, side - 3), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(side * 0.012))
    alpha = np.array(canvas.getchannel("A"), dtype=np.float32) * (np.array(mask, dtype=np.float32) / 255)
    canvas.putalpha(Image.fromarray(alpha.astype(np.uint8)))

    canvas.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS).save(
        os.path.join(OUT, f"{name}_face.png"), optimize=True
    )


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for chara in ("sun", "moon", "earth"):
        sheet = load(chara)
        cut_bodies(chara, sheet)
        cut_icon(chara, sheet)
        print(f"{chara}: 立ち絵4枚 + 顔アイコン1枚")
