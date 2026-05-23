import { buildActiveTabSummary, type ActiveTabSummary, type PermissionState } from '@/shared/permissions';

export async function getActiveTab(): Promise<chrome.tabs.Tab | undefined> {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  return tab;
}

async function containsPermissions(
  permissions: chrome.runtime.ManifestPermissions[],
  origins: string[] = [],
): Promise<boolean> {
  return chrome.permissions.contains({ permissions, origins });
}

export async function getPermissionState(originPattern: string | undefined): Promise<PermissionState> {
  const hasScriptingPermission = await containsPermissions(['scripting']);
  const hasHostPermission = originPattern == null ? false : await containsPermissions([], [originPattern]);

  return { hasHostPermission, hasScriptingPermission };
}

export async function getActiveTabSummary(): Promise<ActiveTabSummary> {
  const tab = await getActiveTab();
  const baseSummary = buildActiveTabSummary(tab);

  if (baseSummary.originPattern == null) {
    return baseSummary;
  }

  return buildActiveTabSummary(tab, await getPermissionState(baseSummary.originPattern));
}

export async function getTabSummary(tabId: number): Promise<ActiveTabSummary> {
  const tab = await chrome.tabs.get(tabId);
  const baseSummary = buildActiveTabSummary(tab);

  if (baseSummary.originPattern == null) {
    return baseSummary;
  }

  return buildActiveTabSummary(tab, await getPermissionState(baseSummary.originPattern));
}
