-- Modchart for "crystallized (Vs. Camellia)" - Maniac
-- Generated for Infinite Engine with ModchartSystem
-- BPM: 174 | Duration: ~735 beats
--
-- FIX: everything moved inside onCreatePost() so that
-- PlayState.instance.modchartSystem already exists when this runs.
-- (startScript() in PlayState.hx runs before modchartSystem is created,
-- so referencing it at file-scope gave you a nil mc and silently did nothing.)

local mc

function postCreate()
    mc = modchartSystem

    mc:prepareMod("drunk", function()
        return DrunkModifier.new()
    end)
    mc:prepareMod("tornado", function()
        return TornadoModifier.new()
    end)
    mc:prepareMod("tipsy", function()
        return TipsyModifier.new()
    end)
    mc:prepareMod("tipsyz", function()
        return TipsyZModifier.new()
    end)
    mc:prepareMod("reverse", function()
        return ReverseModifier.new()
    end)
    mc:prepareMod("flip", function()
        return FlipModifier.new()
    end)
    mc:prepareMod("confusion", function()
        return ConfusionModifier.new()
    end)
    mc:prepareMod("confoffset", function()
        return ConfusionOffsetModifier.new()
    end)
    mc:prepareMod("twirl", function()
        return TwirlModifier.new()
    end)
    mc:prepareMod("shaky", function()
        return ShakyModifier.new()
    end)
    mc:prepareMod("mini", function()
        return MiniModifier.new()
    end)
    mc:prepareMod("pulse", function()
        return PulseModifier.new()
    end)
    mc:prepareMod("stealth", function()
        return StealthModifier.new()
    end)
    mc:prepareMod("blink", function()
        return BlinkModifier.new()
    end)
    mc:prepareMod("z", function()
        return ZModifier.new()
    end)
    mc:prepareMod("speed", function()
        return SpeedModifier.new()
    end)

    -- ========================================================
    -- SECTION 1: INTRO (beats 0–26)
    -- Calm entry — gentle drunk drift to set the mood
    -- ========================================================
    mc:easeMod(0, 8, FlxEase.cubeOut, {
        drunk = 0.15
    })
    mc:easeMod(8, 8, FlxEase.sineInOut, {
        tipsy = 0.1
    })

    -- ========================================================
    -- SECTION A (beats 26–58) — First real section
    -- Tipsy + soft tornado easing in
    -- ========================================================
    mc:setMod(26, {
        drunk = 0.0
    })
    mc:easeMod(26, 4, FlxEase.sineOut, {
        tornado = 0.2
    })
    mc:easeMod(30, 4, FlxEase.sineInOut, {
        tipsy = 0.2
    })
    mc:easeMod(40, 4, FlxEase.sineOut, {
        tipsyz = 0.15
    })
    -- Reset before drop
    mc:easeMod(54, 4, FlxEase.cubeIn, {
        tornado = 0.0,
        tipsy = 0.0,
        tipsyz = 0.0
    })

    -- ========================================================
    -- SECTION B (beats 58–90) — Building intensity
    -- Confusion + speed ramp
    -- ========================================================
    mc:setMod(58, {
        speed = 0.9
    })
    mc:easeMod(58, 8, FlxEase.cubeOut, {
        confusion = 0.2
    })
    mc:easeMod(66, 8, FlxEase.sineInOut, {
        twirl = 0.3
    })
    mc:setMod(72, {
        speed = 1.0
    })
    mc:easeMod(80, 4, FlxEase.cubeIn, {
        confusion = 0.0
    })
    mc:easeMod(84, 4, FlxEase.cubeIn, {
        twirl = 0.0
    })

    -- ========================================================
    -- SECTION C (beats 90–128) — Pre-drop tension
    -- Mini + shaky for a frantic feel
    -- ========================================================
    mc:easeMod(90, 4, FlxEase.elasticOut, {
        mini = 0.3
    })
    mc:easeMod(94, 4, FlxEase.sineInOut, {
        shaky = 0.4
    })
    mc:easeMod(100, 4, FlxEase.sineInOut, {
        drunk = 0.25
    })
    mc:easeMod(108, 4, FlxEase.backOut, {
        tornado = 0.35
    })
    mc:easeMod(116, 4, FlxEase.sineInOut, {
        pulse = 0.6
    })
    -- Clean up before drop 1
    mc:easeMod(122, 6, FlxEase.cubeIn, {
        mini = 0.0,
        shaky = 0.0,
        drunk = 0.0,
        tornado = 0.0,
        pulse = 0.0
    })

    -- ========================================================
    -- DROP 1 (beats 128–154) — First big drop!
    -- Flip + Z depth + speed burst
    -- ========================================================
    mc:setMod(128, {
        flip = 0.0
    })
    mc:easeMod(128, 1, FlxEase.cubeOut, {
        flip = 1.0
    })
    mc:easeMod(128, 2, FlxEase.bounceOut, {
        z = 0.4
    })
    mc:easeMod(128, 2, FlxEase.cubeOut, {
        speed = 1.3
    })

    mc:easeMod(132, 4, FlxEase.sineInOut, {
        drunk = 0.5
    })
    mc:easeMod(136, 4, FlxEase.sineInOut, {
        tornado = 0.5
    })
    mc:setMod(140, {
        confusion = 0.3
    })
    mc:easeMod(140, 4, FlxEase.sineInOut, {
        twirl = 0.4
    })

    -- Drop peak: flip out + confusion
    mc:setMod(144, {
        confoffset = 0.3
    })
    mc:easeMod(144, 4, FlxEase.sineInOut, {
        z = 0.8
    })
    mc:easeMod(148, 4, FlxEase.sineInOut, {
        z = 0.2
    })

    -- Exit drop 1
    mc:easeMod(150, 4, FlxEase.cubeIn, {
        flip = 0.0,
        drunk = 0.0,
        tornado = 0.0,
        confusion = 0.0,
        confoffset = 0.0,
        twirl = 0.0
    })
    mc:easeMod(151, 3, FlxEase.cubeIn, {
        z = 0.0,
        speed = 1.0
    })

    -- ========================================================
    -- BREAK (beats 154–218) — Calm break section
    -- Stealth fade in/out, gentle tipsy
    -- ========================================================
    mc:easeMod(154, 8, FlxEase.sineOut, {
        tipsy = 0.15
    })
    mc:easeMod(162, 8, FlxEase.sineInOut, {
        stealth = 0.3
    })
    mc:easeMod(170, 8, FlxEase.sineInOut, {
        stealth = 0.0
    })
    mc:easeMod(178, 8, FlxEase.sineInOut, {
        tipsyz = 0.2
    })
    mc:easeMod(190, 8, FlxEase.sineInOut, {
        tipsyz = 0.0
    })
    mc:easeMod(200, 8, FlxEase.cubeOut, {
        pulse = 0.4
    })
    mc:easeMod(208, 8, FlxEase.cubeIn, {
        pulse = 0.0
    })
    -- Reset for build
    mc:easeMod(213, 5, FlxEase.cubeIn, {
        tipsy = 0.0
    })

    -- ========================================================
    -- BUILD (beats 218–250) — Re-intensification
    -- Speed up, shaky escalation
    -- ========================================================
    mc:setMod(218, {
        speed = 0.85
    })
    mc:easeMod(218, 16, FlxEase.cubeOut, {
        speed = 1.2
    })
    mc:easeMod(218, 8, FlxEase.sineOut, {
        shaky = 0.3
    })
    mc:easeMod(226, 8, FlxEase.sineInOut, {
        drunk = 0.3
    })
    mc:easeMod(234, 8, FlxEase.sineInOut, {
        tornado = 0.4
    })
    mc:easeMod(242, 4, FlxEase.cubeIn, {
        shaky = 0.0
    })
    mc:easeMod(245, 5, FlxEase.cubeIn, {
        drunk = 0.0,
        tornado = 0.0
    })

    -- ========================================================
    -- DROP 2 (beats 250–288) — Second drop, wilder!
    -- Reverse + confusion + Z + speed boost
    -- ========================================================
    mc:easeMod(250, 0.5, FlxEase.linear, {
        speed = 1.5
    })
    mc:easeMod(250, 1, FlxEase.bounceOut, {
        reverse = 1.0
    })
    mc:easeMod(250, 2, FlxEase.bounceOut, {
        z = 0.6
    })
    mc:easeMod(252, 2, FlxEase.cubeOut, {
        confusion = 0.5
    })

    mc:easeMod(256, 4, FlxEase.sineInOut, {
        tornado = 0.6
    })
    mc:easeMod(260, 4, FlxEase.sineInOut, {
        twirl = 0.5
    })
    mc:setMod(264, {
        flip = 1.0
    })
    mc:easeMod(264, 4, FlxEase.sineInOut, {
        drunk = 0.6
    })

    -- Drop 2 second half — stealth blink
    mc:easeMod(268, 2, FlxEase.cubeOut, {
        blink = 0.7
    })
    mc:easeMod(270, 2, FlxEase.cubeIn, {
        blink = 0.0
    })
    mc:easeMod(272, 4, FlxEase.sineInOut, {
        z = 1.0
    })
    mc:easeMod(276, 4, FlxEase.sineInOut, {
        z = 0.3
    })

    mc:easeMod(280, 4, FlxEase.cubeOut, {
        confoffset = 0.4
    })
    mc:easeMod(282, 4, FlxEase.cubeIn, {
        confoffset = 0.0
    })

    -- Exit drop 2
    mc:easeMod(283, 5, FlxEase.cubeIn, {
        reverse = 0.0,
        confusion = 0.0,
        tornado = 0.0,
        twirl = 0.0,
        drunk = 0.0,
        flip = 0.0
    })
    mc:easeMod(284, 4, FlxEase.cubeIn, {
        z = 0.0,
        speed = 1.0
    })

    -- ========================================================
    -- CALM SECTION (beats 288–314)
    -- Mini pulse, gentle drift
    -- ========================================================
    mc:easeMod(288, 4, FlxEase.elasticOut, {
        mini = 0.5
    })
    mc:easeMod(292, 8, FlxEase.sineInOut, {
        pulse = 0.5
    })
    mc:easeMod(300, 8, FlxEase.sineInOut, {
        tipsy = 0.2
    })
    mc:easeMod(308, 6, FlxEase.cubeIn, {
        mini = 0.0,
        pulse = 0.0,
        tipsy = 0.0
    })

    -- ========================================================
    -- INTENSE SECTION (beats 314–322)
    -- Fast confusion + shaky
    -- ========================================================
    mc:setMod(314, {
        speed = 1.1
    })
    mc:easeMod(314, 2, FlxEase.cubeOut, {
        confusion = 0.8
    })
    mc:easeMod(316, 2, FlxEase.cubeOut, {
        shaky = 0.8
    })
    mc:easeMod(318, 2, FlxEase.cubeIn, {
        confusion = 0.0
    })
    mc:easeMod(320, 2, FlxEase.cubeIn, {
        shaky = 0.0,
        speed = 1.0
    })

    -- ========================================================
    -- BREAKDOWN (beats 322–378)
    -- Stealth + slow speed, eerie feel
    -- ========================================================
    mc:easeMod(322, 4, FlxEase.cubeOut, {
        stealth = 0.5
    })
    mc:setMod(324, {
        speed = 0.8
    })
    mc:easeMod(330, 8, FlxEase.sineInOut, {
        stealth = 0.2
    })
    mc:easeMod(340, 8, FlxEase.sineInOut, {
        tipsyz = 0.3
    })
    mc:easeMod(350, 8, FlxEase.sineInOut, {
        tipsyz = 0.0
    })
    mc:easeMod(360, 8, FlxEase.cubeOut, {
        z = 0.3
    })
    mc:easeMod(368, 8, FlxEase.cubeIn, {
        z = 0.0
    })
    -- Build back up
    mc:easeMod(370, 8, FlxEase.cubeOut, {
        speed = 1.0
    })
    mc:easeMod(374, 4, FlxEase.cubeIn, {
        stealth = 0.0
    })

    -- ========================================================
    -- CHORUS x4 (beats 378–506)
    -- Beat 378: Chorus 1 — Tornado + flip alternating
    -- Beat 410: Chorus 2 — Drunk + confusion peak
    -- Beat 442: Chorus 3 — Everything at once!
    -- Beat 474: Chorus 4 — Wind-down to finale
    -- ========================================================

    -- CHORUS 1 (378–410)
    mc:easeMod(378, 1, FlxEase.bounceOut, {
        flip = 1.0
    })
    mc:easeMod(378, 4, FlxEase.cubeOut, {
        tornado = 0.4
    })
    mc:easeMod(378, 2, FlxEase.bounceOut, {
        speed = 1.2
    })
    mc:easeMod(382, 4, FlxEase.sineInOut, {
        drunk = 0.4
    })
    mc:easeMod(390, 4, FlxEase.sineInOut, {
        twirl = 0.4
    })
    mc:easeMod(396, 4, FlxEase.sineInOut, {
        tornado = 0.0
    })
    mc:easeMod(400, 4, FlxEase.sineInOut, {
        drunk = 0.0
    })
    mc:easeMod(404, 4, FlxEase.cubeIn, {
        twirl = 0.0,
        flip = 0.0
    })
    mc:easeMod(407, 3, FlxEase.cubeIn, {
        speed = 1.0
    })

    -- CHORUS 2 (410–442)
    mc:easeMod(410, 2, FlxEase.cubeOut, {
        drunk = 0.6
    })
    mc:easeMod(410, 1, FlxEase.bounceOut, {
        z = 0.5
    })
    mc:easeMod(414, 2, FlxEase.cubeOut, {
        confusion = 0.5
    })
    mc:easeMod(418, 4, FlxEase.sineInOut, {
        tornado = 0.5,
        tipsyz = 0.3
    })
    mc:easeMod(424, 2, FlxEase.cubeOut, {
        blink = 0.6
    })
    mc:easeMod(426, 2, FlxEase.cubeIn, {
        blink = 0.0
    })
    mc:easeMod(430, 4, FlxEase.sineInOut, {
        drunk = 0.0
    })
    mc:easeMod(434, 4, FlxEase.sineInOut, {
        confusion = 0.0,
        tornado = 0.0
    })
    mc:easeMod(436, 4, FlxEase.cubeIn, {
        tipsyz = 0.0,
        z = 0.0
    })

    -- CHORUS 3 — Peak chaos! (442–474)
    mc:easeMod(442, 0.5, FlxEase.linear, {
        speed = 1.4
    })
    mc:easeMod(442, 1, FlxEase.bounceOut, {
        flip = 1.0
    })
    mc:easeMod(442, 1, FlxEase.bounceOut, {
        reverse = 1.0
    })
    mc:easeMod(442, 2, FlxEase.cubeOut, {
        z = 0.7
    })
    mc:easeMod(444, 2, FlxEase.cubeOut, {
        drunk = 0.7
    })
    mc:easeMod(446, 2, FlxEase.cubeOut, {
        tornado = 0.6
    })
    mc:easeMod(448, 2, FlxEase.cubeOut, {
        confusion = 0.6
    })
    mc:easeMod(452, 4, FlxEase.sineInOut, {
        twirl = 0.5
    })
    mc:easeMod(456, 4, FlxEase.sineInOut, {
        pulse = 0.8
    })
    mc:easeMod(460, 2, FlxEase.cubeOut, {
        blink = 0.8
    })
    mc:easeMod(462, 2, FlxEase.cubeIn, {
        blink = 0.0
    })
    mc:easeMod(462, 4, FlxEase.cubeIn, {
        z = 0.0,
        drunk = 0.0
    })
    mc:easeMod(464, 4, FlxEase.cubeIn, {
        tornado = 0.0,
        confusion = 0.0
    })
    mc:easeMod(466, 4, FlxEase.cubeIn, {
        twirl = 0.0,
        pulse = 0.0
    })
    mc:easeMod(468, 4, FlxEase.cubeIn, {
        reverse = 0.0,
        flip = 0.0
    })
    mc:easeMod(470, 4, FlxEase.cubeIn, {
        speed = 1.0
    })

    -- CHORUS 4 (474–506) — Slower, more melodic
    mc:easeMod(474, 4, FlxEase.sineOut, {
        tipsy = 0.3
    })
    mc:easeMod(478, 8, FlxEase.sineInOut, {
        tipsyz = 0.3
    })
    mc:easeMod(486, 8, FlxEase.sineInOut, {
        mini = 0.4
    })
    mc:easeMod(490, 8, FlxEase.sineInOut, {
        pulse = 0.5
    })
    mc:easeMod(498, 8, FlxEase.cubeIn, {
        tipsy = 0.0,
        tipsyz = 0.0,
        mini = 0.0,
        pulse = 0.0
    })

    -- ========================================================
    -- OUTRO / FINAL SECTIONS (506–735)
    -- ========================================================

    -- Outro Begin (506–570)
    mc:easeMod(506, 8, FlxEase.cubeOut, {
        stealth = 0.35
    })
    mc:setMod(510, {
        speed = 0.9
    })
    mc:easeMod(514, 8, FlxEase.sineInOut, {
        z = 0.25
    })
    mc:easeMod(530, 8, FlxEase.sineInOut, {
        stealth = 0.15
    })
    mc:easeMod(546, 8, FlxEase.sineInOut, {
        z = 0.0
    })
    mc:easeMod(558, 8, FlxEase.cubeIn, {
        stealth = 0.0
    })
    mc:easeMod(562, 8, FlxEase.cubeOut, {
        speed = 1.0
    })

    -- Outro Mid (570–634) — Final intensity build
    mc:easeMod(570, 8, FlxEase.cubeOut, {
        drunk = 0.3
    })
    mc:easeMod(578, 8, FlxEase.sineInOut, {
        tornado = 0.3
    })
    mc:easeMod(586, 8, FlxEase.cubeOut, {
        speed = 1.1
    })
    mc:easeMod(594, 8, FlxEase.sineInOut, {
        confusion = 0.3
    })
    mc:easeMod(602, 8, FlxEase.sineInOut, {
        twirl = 0.3
    })
    mc:easeMod(614, 8, FlxEase.cubeIn, {
        drunk = 0.0,
        tornado = 0.0
    })
    mc:easeMod(620, 8, FlxEase.cubeIn, {
        confusion = 0.0,
        twirl = 0.0
    })
    mc:easeMod(626, 8, FlxEase.cubeIn, {
        speed = 1.0
    })

    -- Final Section (634–698) — Ultimate climax
    mc:easeMod(634, 1, FlxEase.bounceOut, {
        flip = 1.0
    })
    mc:easeMod(634, 2, FlxEase.cubeOut, {
        speed = 1.35
    })
    mc:easeMod(634, 4, FlxEase.cubeOut, {
        z = 0.5
    })
    mc:easeMod(636, 4, FlxEase.cubeOut, {
        drunk = 0.5
    })
    mc:easeMod(640, 4, FlxEase.cubeOut, {
        tornado = 0.5
    })
    mc:easeMod(644, 4, FlxEase.sineInOut, {
        twirl = 0.5
    })
    mc:easeMod(648, 4, FlxEase.sineInOut, {
        confusion = 0.5
    })
    mc:easeMod(654, 4, FlxEase.cubeOut, {
        blink = 0.6
    })
    mc:easeMod(658, 2, FlxEase.cubeIn, {
        blink = 0.0
    })
    mc:easeMod(660, 4, FlxEase.sineInOut, {
        tipsyz = 0.4
    })
    mc:easeMod(666, 4, FlxEase.cubeIn, {
        drunk = 0.0,
        tornado = 0.0
    })
    mc:easeMod(670, 4, FlxEase.cubeIn, {
        twirl = 0.0,
        confusion = 0.0
    })
    mc:easeMod(674, 4, FlxEase.cubeIn, {
        tipsyz = 0.0,
        z = 0.0
    })
    mc:easeMod(678, 4, FlxEase.cubeIn, {
        flip = 0.0,
        speed = 1.0
    })

    -- End Sequence (698–735) — Fade out feel
    mc:easeMod(698, 8, FlxEase.sineOut, {
        stealth = 0.4
    })
    mc:easeMod(706, 8, FlxEase.sineOut, {
        mini = 0.5
    })
    mc:easeMod(714, 8, FlxEase.sineInOut, {
        pulse = 0.4
    })
    mc:easeMod(720, 8, FlxEase.cubeOut, {
        stealth = 0.6
    })
    mc:easeMod(725, 8, FlxEase.cubeIn, {
        stealth = 0.0,
        mini = 0.0,
        pulse = 0.0
    })
    -- Final: everything off
    mc:easeMod(730, 5, FlxEase.linear, {
        drunk = 0.0,
        tornado = 0.0,
        tipsy = 0.0,
        tipsyz = 0.0,
        flip = 0.0,
        reverse = 0.0,
        confusion = 0.0,
        twirl = 0.0,
        shaky = 0.0,
        mini = 0.0,
        pulse = 0.0,
        stealth = 0.0,
        blink = 0.0,
        z = 0.0,
        speed = 1.0
    })

end