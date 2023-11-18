#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// If the gamerules vtable index changes too often, flip this to try pattern
// scanning, instead.
#define USE_SIGSCAN false

#define LINUX_GAMERULES_GETNEXTMAP_NAME "@_ZN13CDYSGameRules16GetNextLevelNameEPci"

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
        int vtable_index = (IsLinux() ? 0x2B8 : 0x2B4) / 4;
        PrepSDKCall_SetVirtual(vtable_index);
#else // USE_SIGSCAN
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
