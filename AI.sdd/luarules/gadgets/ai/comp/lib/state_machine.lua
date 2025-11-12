local M = {}

function M.Create(owner)
    local sm = {
        owner = owner,
        states = {},
        current = nil,
        previous = nil,
        ticksInState = 0,
    }

    function sm:define(name, state)
        self.states[name] = state
        return self
    end

    function sm:defineAll(tbl)
        for k, v in pairs(tbl or {}) do
            self:define(k, v)
        end
        return self
    end

    function sm:resolve(state)
        if type(state) == "string" then
            return self.states[state]
        end
        return state
    end

    function sm:setState(state)
        local nextState = self:resolve(state)
        if nextState == self.current then return end
        local prev = self.current
        if prev and prev.exit then prev:exit(self, nextState) end
        self.previous = prev
        self.current = nextState
        self.ticksInState = 0
        if nextState and nextState.enter then nextState:enter(self, prev) end
    end

    function sm:transition(state)
        self:setState(state)
    end

    function sm:update()
        self.ticksInState = (self.ticksInState or 0) + 1
        local cur = self.current
        if not cur then return end
        local nextState = cur.tick and cur:tick(self)
        if nextState ~= nil then
            self:setState(nextState)
        end
    end

    function sm:getState()
        return self.current
    end

    function sm:isIn(state)
        local resolved = self:resolve(state)
        return resolved ~= nil and resolved == self.current
    end

    return sm
end

return M
