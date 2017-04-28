function clear(name, value)
    if value > 0 then
        mp.osd_message(" ", 0.01)
        mp.set_osd_ass(0, 0, "")
        --mp.unobserve_property(clear)
    end
end
mp.observe_property("osd-width", "number", clear)
