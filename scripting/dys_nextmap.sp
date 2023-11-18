#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// HACK: should figure this out at runtime using gamedata, so this "just works".
#define PLATFORM_LINUX32 0
#define PLATFORM_WIN32 1
#define PLATFORM_CHANGE_ME 0xDEADBEEF
#define SERVER_PLATFORM ((( PLATFORM_CHANGE_ME ))) // <-- CHANGE THIS!
#if (SERVER_PLATFORM != PLATFORM_LINUX32 && SERVER_PLATFORM != PLATFORM_WIN32)
#error Please set SERVER_PLATFORM to PLATFORM_LINUX32 or PLATFORM_WIN32 before compiling.
#endif

// If the gamerules vtable index changes too often, flip this to try pattern
// scanning, instead.
#define USE_SIGSCAN false

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
#if(!USE_SIGSCAN)
        int vtable_index =
#if(SERVER_PLATFORM == PLATFORM_LINUX32)
            0x2B8;
#elseif(SERVER_PLATFORM == PLATFORM_WIN32)
            0x2B4;
#endif
        PrepSDKCall_SetVirtual(vtable_index / 4);
#else // USE_SIGSCAN
        char sig[] =
#if(SERVER_PLATFORM == PLATFORM_LINUX32)
            "@_ZN13CDYSGameRules16GetNextLevelNameEPci";
#elseif(SERVER_PLATFORM == PLATFORM_WIN32)
            "\x55\x8B\xEC\x8B\x81\xEC\x02\x00\x00";
#endif
        PrepSDKCall_SetSignature(SDKLibrary_Server, sig, sizeof(sig) - 1);
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
