import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'fish',
  tagline: 'An experiential typed framework for Roblox.',

  plugins: [
    [
      'docusaurus-plugin-moonwave',
      {
        id: 'default',
        projectRoot: '../',   // where your Lua + moonwave.toml live
        apiDir: 'api',        // output dir for` Moonwave JSON/docs
        code: "../src",
        classOrder: [],
        apiCategories: []
      },
    ]
  ],

  // Set the production url of your site here
  url: 'https://stevendahfish.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/fish/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'StevenDahFish', // Usually your GitHub org/user name.
  projectName: 'fish', // Usually your repo name.
  deploymentBranch: 'gh-pages',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  trailingSlash: false,

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          lastVersion: '1.1.8',
          versions: {
            current: {
              label: '2.0.0+',
              // badge: false,
              // path: ''
            },
            '1.1.8': {
              label: '1.1.8',
              // path: "1.1.8",

              // remove after:
              badge: false
            }
          }
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'fish',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {to: '/api', label: 'API', position: 'left'},
        {to: '/changelog', label: 'Changelog', position: 'left'},
        {
          type: 'docsVersionDropdown',
          position: 'right',
        },
        {
          href: 'https://github.com/StevenDahFish/fish',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      copyright: `Copyright © ${new Date().getFullYear()} StevenDahFish. Built with Moonwave and Docusaurus.`,
    },
    colorMode: {
      defaultMode: "dark"
    }
  } satisfies Preset.ThemeConfig,
};

export default config;
