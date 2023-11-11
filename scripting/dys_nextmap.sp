#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

/**
Print the Dystopia console command "nextmap" value to chat.
Works both from client console (SRCDS only), and from game chat.
If this ever breaks with a game update, try flipping the #if(1) switch at around line 69 to #if(0)
**/

public Plugin myinfo = {
    name = "Dystopia nextmap",
    description = "Print the Dystopia \"nextmap\" value to chat.",
    author = "Rain",
    version = "0.1.0",
    url = "https://gist.github.com/Rainyan/87d196b45c8928838d3e8d435306eaf3"
};

public void OnPluginStart()
{
    // if you wanted to print the map from console message
    RegConsoleCmd("nextmap", Cmd_NextMap);

    // if you wanted to print the map from say message
    if (!AddCommandListener(OnSay, "say") ||
        !AddCommandListener(OnSay, "say_team"))
    {
        SetFailState("Failed to add command listener");
    }
}

public Action Cmd_NextMap(int client, int argc)
{
    if (client != 0)
    {
        PrintNextmap(client);
    }
    return Plugin_Continue;
}

public Action OnSay(int client, const char[] command, int argc)
{
    if (argc != 1 || client == 0)
    {
        return Plugin_Continue;
    }
    // 1 more than needed, because don't wanna strequal strings that start with
    // (but don't equal) our target phrase
    char msg[7 + 1 + 1];
    GetCmdArg(1, msg, sizeof(msg));
    if (!StrEqual(msg, "nextmap", false))
    {
        return Plugin_Continue;
    }

    PrintNextmap(client);
    return Plugin_Continue;
}

void PrintNextmap(int client)
{
    static Handle call = INVALID_HANDLE;
    if (call == INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_GameRules);
#if(1)
        PrepSDKCall_SetVirtual(0x2B4 / 4);
#else
        // If the vtable index changes a lot with game updates, this signature scan may work better
        PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x8B\x81\xEC\x02\x00\x00", 9);
#endif
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        call = EndPrepSDKCall();
        if (call == INVALID_HANDLE)
        {
            SetFailState("Failed to prepare SDK call");
        }
    }
    char nextmap[PLATFORM_MAX_PATH];
    SDKCall(call, nextmap, sizeof(nextmap));
    PrintToChat(client, "Next map is %s.", nextmap); // or PrintToChatAll
}
