#include <regex>

Regex g_FilterRegex = null;

void LoadWordFilter()
{
    if (g_FilterRegex != null)
    {
        delete g_FilterRegex;
        g_FilterRegex = null;
    }

    if (!g_sFilterWords[0])
        return;

    RegexError err;
    g_FilterRegex = new Regex(g_sFilterWords, PCRE_CASELESS, "", 0, err);
    if (g_FilterRegex == null || err != REGEX_ERROR_NONE)
    {
        if (g_FilterRegex != null)
        {
            delete g_FilterRegex;
            g_FilterRegex = null;
        }
    }
}

bool WordFilter_ShouldBlock(const char[] message)
{
    if (g_FilterRegex == null)
        return false;

    RegexError err;
    return g_FilterRegex.Match(message, err) > 0;
}

public void WordFilter_OnPluginStart()
{
    LoadWordFilter();
    g_cvFilterWords.AddChangeHook(WordFilter_OnFilterWordsChanged);
}

public void WordFilter_OnFilterWordsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    g_cvFilterWords.GetString(g_sFilterWords, sizeof(g_sFilterWords));
    LoadWordFilter();
}