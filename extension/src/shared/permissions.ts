export type AnnotatablePageStatus = 'enabled' | 'needs-permission' | 'unsupported';

export type ActiveTabSummary = {
  tabId?: number;
  title?: string;
  url?: string;
  origin?: string;
  originPattern?: string;
  canAnnotate: boolean;
  hasHostPermission: boolean;
  hasScriptingPermission: boolean;
  status: AnnotatablePageStatus;
  reason?: string;
};

export type PermissionState = { hasHostPermission: boolean; hasScriptingPermission: boolean };

export function getOriginPattern(url: string): string | undefined {
  try {
    const parsedUrl = new URL(url);
    if (parsedUrl.protocol !== 'http:' && parsedUrl.protocol !== 'https:') {
      return undefined;
    }

    return `${parsedUrl.origin}/*`;
  } catch {
    return undefined;
  }
}

export function getOrigin(url: string): string | undefined {
  try {
    const parsedUrl = new URL(url);
    if (parsedUrl.protocol !== 'http:' && parsedUrl.protocol !== 'https:') {
      return undefined;
    }

    return parsedUrl.origin;
  } catch {
    return undefined;
  }
}

export function buildActiveTabSummary(
  tab: Pick<chrome.tabs.Tab, 'id' | 'title' | 'url'> | undefined,
  pem?: PermissionState,
): ActiveTabSummary {
  const permissionState = pem ?? { hasHostPermission: false, hasScriptingPermission: false };
  if (tab?.url == null) {
    return {
      tabId: tab?.id,
      title: tab?.title,
      canAnnotate: false,
      hasHostPermission: false,
      hasScriptingPermission: false,
      status: 'unsupported',
      reason: 'No active page URL is available.',
    };
  }

  const origin = getOrigin(tab.url);
  const originPattern = getOriginPattern(tab.url);

  if (origin == null || originPattern == null) {
    return {
      tabId: tab.id,
      title: tab.title,
      url: tab.url,
      canAnnotate: false,
      hasHostPermission: false,
      hasScriptingPermission: permissionState.hasScriptingPermission,
      status: 'unsupported',
      reason: 'Marker can annotate ordinary http and https pages only.',
    };
  }

  const canAnnotate = permissionState.hasHostPermission && permissionState.hasScriptingPermission;

  return {
    tabId: tab.id,
    title: tab.title,
    url: tab.url,
    origin,
    originPattern,
    canAnnotate,
    hasHostPermission: permissionState.hasHostPermission,
    hasScriptingPermission: permissionState.hasScriptingPermission,
    status: canAnnotate ? 'enabled' : 'needs-permission',
  };
}
