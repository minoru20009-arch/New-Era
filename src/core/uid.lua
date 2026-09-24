-- Stable per-run identifiers for cards.
-- Vanilla sort_id is not safe across save/load (G.sort_id is not saved), so references
-- between cards (bindings, protection, stored abilities) use ability.ne_uid instead.

NE.UID = NE.UID or {}
local UID = NE.UID

UID.extra_areas = UID.extra_areas or {} -- functions returning a CardArea (or nil)

function UID.next()
    local s = NE.State.get()
    if not s then return nil end
    local id = s.next_uid
    s.next_uid = id + 1
    return id
end

-- Returns the card's uid, assigning one if needed. Returns nil outside a run.
function UID.of(card)
    if not (card and card.ability) then return nil end
    local id = card.ability.ne_uid
    if id == nil then
        id = UID.next()
        card.ability.ne_uid = id
    end
    return id
end

-- Lets other modules make their own CardAreas searchable by UID.find.
function UID.register_area(getter)
    UID.extra_areas[#UID.extra_areas + 1] = getter
end

local function search(area, uid)
    if not (area and area.cards) then return nil end
    for i = 1, #area.cards do
        local c = area.cards[i]
        if c.ability and c.ability.ne_uid == uid then return c end
    end
    return nil
end

-- Finds a card by uid in the standard areas and any registered extra areas.
function UID.find(uid)
    if uid == nil or not G then return nil end
    local found = search(G.jokers, uid) or search(G.consumeables, uid) or search(G.hand, uid)
        or search(G.play, uid) or search(G.deck, uid) or search(G.discard, uid)
    if found then return found end
    for i = 1, #UID.extra_areas do
        found = search(UID.extra_areas[i](), uid)
        if found then return found end
    end
    return nil
end
