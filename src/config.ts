const ensureTrailingSlash = (value: string) => value.replace(/\/?$/, "/");

const website = ensureTrailingSlash(
  process.env.SITE_URL?.trim() || "https://edxi.github.io/"
);

const profile = ensureTrailingSlash(
  process.env.SITE_PROFILE_URL?.trim() || website
);

export const SITE = {
  website,
  author: "阿德",
  profile,
  desc: "阿德的博客 - 记录技术与生活",
  title: "阿德的博客",
  ogImage: "astropaper-og.jpg",
  lightAndDarkMode: true,
  postPerIndex: 4,
  postPerPage: 4,
  scheduledPostMargin: 15 * 60 * 1000, // 15 minutes
  showArchives: true,
  showBackButton: true, // show back button in post detail
  editPost: {
    enabled: false,
    text: "Edit page",
    url: "https://github.com/miniade/astro-blog/edit/main/",
  },
  dynamicOgImage: true,
  dir: "ltr", // "rtl" | "auto"
  lang: "zh-CN", // html lang code. Set this empty and default will be "en"
  timezone: "Asia/Shanghai", // Default global timezone (IANA format) https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
} as const;
