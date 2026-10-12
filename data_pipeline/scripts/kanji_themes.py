"""
Curated themes for the kanji course (ui-design §5.2), the kanji counterpart
of the kana "rows": every unit on the path is one theme.

Each N5/N4 course kanji belongs to exactly one theme of its own level
(build_content_db.py fails otherwise). Theme keys are translated in the app
(`kanjiTheme` in lib/l10n/*.arb). Themes are sorted by the average difficulty
rank of their kanji (school grade, strokes, frequency), so the course still
runs from easiest to hardest; within a theme the kanji are taught in the
order written here (一二三…, 日月火…), split into lessons of about five.
"""

THEMES: dict[int, dict[str, str]] = {
    5: {
        "numbers": "一二三四五六七八九十百千万円",
        "people": "人口目耳手足子女男",
        "week": "日月火水木金土",
        "nature": "山川天空雨気花魚",
        "position": "上下中右左前後外東西南北",
        "qualities": "大小多少高安長古新白",
        "clock": "時分午半今毎週年間",
        "intro": "名何先生友父母",
        "actions": "見行来入出立休食飲買",
        "school": "学校本書読語言話聞",
        "town": "車道店駅電国会社",
    },
    4: {
        "colors": "色赤青黒明暗光",
        "family": "家族親兄弟姉妹私自主",
        "health": "体頭顔首声心力元医病院薬死",
        "landscape": "田林森地池海野風",
        "seasons": "春夏秋冬朝昼夕夜早曜計去暑寒",
        "food": "肉牛犬鳥茶味菜飯",
        "regions": "世界村町市区県都京民",
        "buildings": "門室台所屋館堂場住建",
        "travel": "走歩通乗運転旅帰発送急動進",
        "size": "太広近遠強弱重軽短低",
        "judgement": "正同別特便有不以悪",
        "mind": "思考知意好楽理真",
        "study": "教習勉研究問答題試験質",
        "arts": "文字漢英音歌画写映図紙方説",
        "work": "仕事工業者員働用",
        "shopping": "売物品代料銀借貸産",
        "doing": "作使持待開集引止切合注",
        "daily": "起洗服着洋始終回度",
    },
}


def theme_of() -> dict[str, tuple[int, str, int]]:
    """kanji → (level, theme key, position in theme); raises on duplicates."""
    out: dict[str, tuple[int, str, int]] = {}
    for level, themes in THEMES.items():
        for key, chars in themes.items():
            for i, c in enumerate(chars):
                if c in out:
                    raise ValueError(f"{c} is in both {out[c][1]} and {key}")
                out[c] = (level, key, i)
    return out
