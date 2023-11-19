#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// If the gamerules vtable index changes too often, flip this to try pattern
// scanning, instead.
#define USE_SIGSCAN false

#define LINUX_GAMERULES_GETNEXTMAP_NAME "@_ZN13CDYSGameRules16GetNextLevelNameEPci"

public Plugin myinfo = {
    name = "Dystopia nextmap",
    description = "Print the Dystopia \"nextmap\" value to chat.\
Works both from client console (SRCDS only), and from game chat.",
    author = "Rain",
    version = "0.1.0",
    url = "https://github.com/bauxiteDYS/SM-DYS-NextMap"
};

public void OnPluginStart()
{
    if (!AddCommandListener(OnNextMap, "nextmap") ||
        !AddCommandListener(OnSay, "say") ||
        !AddCommandListener(OnSay, "say_team"))
    {
        SetFailState("Failed to add command listener");
    }
}

public Action OnNextMap(int client, const char[] command, int argc)
{
    if (argc == 0 && client != 0)
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
    if (StrEqual(msg, "nextmap", false))
    {
        PrintNextmap(client);
    }
    return Plugin_Continue;
}

void PrintNextmap(int client)
{
    static Handle call = INVALID_HANDLE;
    if (call == INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_GameRules);
#if(!USE_SIGSCAN)
        int vtable_index = (IsLinux() ? 0x2B8 : 0x2B4) / 4;
        PrepSDKCall_SetVirtual(vtable_index);
#else
        if (IsLinux())
        {
            char sig[] = LINUX_GAMERULES_GETNEXTMAP_NAME;
            PrepSDKCall_SetSignature(SDKLibrary_Server, sig, sizeof(sig) - 1);
        }
        else
        {
            char sig[] = "\x55\x8B\xEC\x8B\x81\xEC\x02\x00\x00";
            PrepSDKCall_SetSignature(SDKLibrary_Server, sig, sizeof(sig) - 1);
        }
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

bool IsLinux()
{
    static bool first_run = true;
    static bool found;
    if (first_run)
    {
        first_run = !first_run;
        StartPrepSDKCall(SDKCall_GameRules);
        char sig[] = LINUX_GAMERULES_GETNEXTMAP_NAME;
        found = PrepSDKCall_SetSignature(SDKLibrary_Server, sig, sizeof(sig) - 1);
        EndPrepSDKCall();
    }
    return found;
}