-- Texture atlases. New Era draws joker art with shaders (Phase 12); until then every joker
-- uses a plain tier frame from this atlas.
-- Frame order: x=0 Unranked, x=1 Demonic, x=2 Heavenly, x=3 hybrid (Demonic + Heavenly).

SMODS.Atlas {
    key = 'frames',
    path = 'ne_frames.png',
    px = 71,
    py = 95,
}

NE.FRAME_POS = {
    [NE.RARITY.UNRANKED] = { x = 0, y = 0 },
    [NE.RARITY.DEMONIC] = { x = 1, y = 0 },
    [NE.RARITY.HEAVENLY] = { x = 2, y = 0 },
    hybrid = { x = 3, y = 0 },
}
