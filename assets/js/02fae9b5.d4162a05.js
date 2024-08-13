"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[331],{3905:(e,t,n)=>{n.d(t,{Zo:()=>s,kt:()=>m});var r=n(67294);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function a(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function i(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?a(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):a(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},a=Object.keys(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var p=r.createContext({}),c=function(e){var t=r.useContext(p),n=t;return e&&(n="function"==typeof e?e(t):i(i({},t),e)),n},s=function(e){var t=c(e.components);return r.createElement(p.Provider,{value:t},e.children)},u="mdxType",f={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},d=r.forwardRef((function(e,t){var n=e.components,o=e.mdxType,a=e.originalType,p=e.parentName,s=l(e,["components","mdxType","originalType","parentName"]),u=c(n),d=o,m=u["".concat(p,".").concat(d)]||u[d]||f[d]||a;return n?r.createElement(m,i(i({ref:t},s),{},{components:n})):r.createElement(m,i({ref:t},s))}));function m(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var a=n.length,i=new Array(a);i[0]=d;var l={};for(var p in t)hasOwnProperty.call(t,p)&&(l[p]=t[p]);l.originalType=e,l[u]="string"==typeof e?e:o,i[1]=l;for(var c=2;c<a;c++)i[c]=n[c];return r.createElement.apply(null,i)}return r.createElement.apply(null,n)}d.displayName="MDXCreateElement"},76647:(e,t,n)=>{n.r(t),n.d(t,{contentTitle:()=>i,default:()=>u,frontMatter:()=>a,metadata:()=>l,toc:()=>p});var r=n(87462),o=(n(67294),n(3905));const a={},i="fish",l={type:"mdx",permalink:"/fish/",source:"@site/pages/index.md",title:"fish",description:"An experiential (involving or based on experience and observation) typed framework for Roblox.",frontMatter:{}},p=[{value:"Installation",id:"installation",level:2},{value:"Documentation",id:"documentation",level:2},{value:"Structure",id:"structure",level:2}],c={toc:p},s="wrapper";function u(e){let{components:t,...n}=e;return(0,o.kt)(s,(0,r.Z)({},c,n,{components:t,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"fish"},"fish"),(0,o.kt)("p",null,"An ",(0,o.kt)("strong",{parentName:"p"},"experiential")," (",(0,o.kt)("em",{parentName:"p"},"involving or based on experience and observation"),") typed framework for Roblox."),(0,o.kt)("p",null,"This framework is inspired from ",(0,o.kt)("a",{parentName:"p",href:"https://github.com/Sleitnick/Knit"},"Knit")," and was created in response to the project being archived."),(0,o.kt)("h2",{id:"installation"},"Installation"),(0,o.kt)("p",null,(0,o.kt)("strong",{parentName:"p"},"Wally & Rojo workflow:")),(0,o.kt)("ol",null,(0,o.kt)("li",{parentName:"ol"},"Add Knit as a Wally dependency (e.g. ",(0,o.kt)("inlineCode",{parentName:"li"},'fish = "stevendahfish/fish@^1"'),")"),(0,o.kt)("li",{parentName:"ol"},"Use Rojo to point the Wally packages to ReplicatedStorage.")),(0,o.kt)("h2",{id:"documentation"},"Documentation"),(0,o.kt)("p",null,"View the ",(0,o.kt)("a",{parentName:"p",href:"https://stevendahfish.github.io/fish/"},"documentation")," to see how to use this framework."),(0,o.kt)("h2",{id:"structure"},"Structure"),(0,o.kt)("p",null,"The structure of projects was tightly integrated into the framework, meaning the way Services and Controllers are organized are strict and should not be changed in order to provide typings as expected. View the ",(0,o.kt)("a",{parentName:"p",href:"https://github.com/StevenDahFish/fish/blob/master/tests"},"tests")," folder for an example of this."))}u.isMDXComponent=!0}}]);