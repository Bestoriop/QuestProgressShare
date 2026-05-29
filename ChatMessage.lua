-- ChatMessage.lua: Handles sending quest progress and completion messages to chat, party, and addon channels for QuestProgressShare.
-- Provides message formatting, coloring, and robust party/addon communication logic.
local QPS = QuestProgressShare
QPS.chatMessage = {}

-- Helper function to determine if an objective is complete
local function IsObjectiveComplete(text, finished, objectiveFinished)
    if objectiveFinished == true then
        return true
    end
    local current, required = StringLib.SafeExtractNumbers(text or "")
    if current and required then
        current = tonumber(current)
        required = tonumber(required)
        if current and required and current >= required then
            return true
        end
    end
    if finished then
        return true
    end
    return false
end

-- Sends a quest progress message to chat, party, and/or addon channels based on config.
-- Called when pfQuest is not available (no clickable link).
function QPS.chatMessage.Send(title, text, finished, objectiveIndex, objectiveFinished)
    LogVerboseDebugMessage(QPS_CoreDebugLog, "[QPS-DEBUG] QPS.chatMessage.Send called: title=" .. tostring(title) .. ", text=" .. tostring(text) .. ", finished=" .. tostring(finished) .. ", objectiveIndex=" .. tostring(objectiveIndex) .. ", objectiveFinished=" .. tostring(objectiveFinished))
    if QuestProgressShareConfig then
        LogVerboseDebugMessage(QPS_CoreDebugLog, "[QPS-DEBUG] sendSelf=" .. tostring(QuestProgressShareConfig.sendSelf) .. ", sendPublic=" .. tostring(QuestProgressShareConfig.sendPublic) .. ", sendInParty=" .. tostring(QuestProgressShareConfig.sendInParty))
    else
        LogDebugMessage(QPS_CoreDebugLog, "[QPS-DEBUG] QuestProgressShareConfig is nil!")
    end
    local isObjectiveComplete = IsObjectiveComplete(text, finished, objectiveFinished)
    -- Send to self (local chat frame only, with color)
    if (QuestProgressShareConfig.sendSelf) then
        local selfMessage = title .. " - " .. text
        if isObjectiveComplete then
            DEFAULT_CHAT_FRAME:AddMessage("[" .. UnitName("player") .. "]: " .. selfMessage, 0, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[" .. UnitName("player") .. "]: " .. selfMessage, 1, 0, 0)
        end
    end
    -- Plain text for network channels (no color codes)
    local networkMessage = title .. " - " .. tostring(text or "")
    -- Send to public (/say)
    if (QuestProgressShareConfig.sendPublic) then
        SendChatMessage(networkMessage, "SAY")
    end
    -- Send to raid or party
    if (QuestProgressShareConfig.sendInRaid == 1) then
        SendChatMessage(networkMessage, "RAID")
    elseif (QuestProgressShareConfig.sendInParty == 1) then
        SendChatMessage(networkMessage, "PARTY")
    end
end

-- Sends a quest progress message with a clickable pfQuest link to chat, party, and/or addon channels based on config.
-- Called when pfQuest is available. Uses plainTitle for network channels to avoid server-side filtering.
function QPS.chatMessage.SendLink(link, text, finished, objectiveIndex, objectiveFinished, plainTitle)
    LogVerboseDebugMessage(QPS_CoreDebugLog, "[QPS-DEBUG] QPS.chatMessage.SendLink called: link=" .. tostring(link) .. ", text=" .. tostring(text) .. ", finished=" .. tostring(finished) .. ", objectiveIndex=" .. tostring(objectiveIndex) .. ", objectiveFinished=" .. tostring(objectiveFinished))
    if not QuestProgressShareConfig or QuestProgressShareConfig.enabled ~= 1 then
        LogDebugMessage(QPS_CoreDebugLog, "[QPS-DEBUG] SendLink: config missing or disabled! enabled=" .. tostring(QuestProgressShareConfig and QuestProgressShareConfig.enabled))
        return
    end
    LogVerboseDebugMessage(QPS_CoreDebugLog, "[QPS-DEBUG] sendSelf=" .. tostring(QuestProgressShareConfig.sendSelf) .. ", sendPublic=" .. tostring(QuestProgressShareConfig.sendPublic) .. ", sendInParty=" .. tostring(QuestProgressShareConfig.sendInParty))
    local isObjectiveComplete = IsObjectiveComplete(text, finished, objectiveFinished)
    -- Build colored message with clickable link for local display
    local message
    if text and text ~= "" then
        if isObjectiveComplete then
            message = link .. " |cff00ff00- " .. text .. "|r"
        else
            message = link .. " |cffff0000- " .. text .. "|r"
        end
    else
        message = link
    end
    -- Send to self (local chat frame only, with colored link)
    if (QuestProgressShareConfig.sendSelf) then
        DEFAULT_CHAT_FRAME:AddMessage("[" .. UnitName("player") .. "]: " .. message)
    end
    -- Plain text for network channels: use plainTitle to avoid server-side filtering of color codes and brackets
    local safeText = tostring(text or "")
    local networkMessage
    if plainTitle and plainTitle ~= "" then
        networkMessage = plainTitle .. " - " .. safeText
    else
        networkMessage = safeText
    end
    -- Send to public (/say)
    if (QuestProgressShareConfig.sendPublic and QuestProgressShareConfig.sendPublic ~= 0) then
        SendChatMessage(networkMessage, "SAY")
    end
    -- Send to raid or party
    if (QuestProgressShareConfig.sendInRaid == 1) then
        SendChatMessage(networkMessage, "RAID")
    elseif (QuestProgressShareConfig.sendInParty == 1) then
        SendChatMessage(networkMessage, "PARTY")
    end
end
