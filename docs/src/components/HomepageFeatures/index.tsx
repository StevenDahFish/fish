import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Strictly typed',
    Svg: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmZmZmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1icmljay13YWxsIj48cmVjdCB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHg9IjMiIHk9IjMiIHJ4PSIyIi8+PHBhdGggZD0iTTEyIDl2NiIvPjxwYXRoIGQ9Ik0xNiAxNXY2Ii8+PHBhdGggZD0iTTE2IDN2NiIvPjxwYXRoIGQ9Ik0zIDE1aDE4Ii8+PHBhdGggZD0iTTMgOWgxOCIvPjxwYXRoIGQ9Ik04IDE1djYiLz48cGF0aCBkPSJNOCAzdjYiLz48L3N2Zz4=',
    description: (
      <>
        Typing being the primary focus of this framework allows intellisense to do most of the work for you
      </>
    ),
  },
  {
    title: 'Heavily Knit-inspired',
    Svg: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmZmZmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1jbG91ZCI+PHBhdGggZD0iTTE3LjUgMTlIOWE3IDcgMCAxIDEgNi43MS05aDEuNzlhNC41IDQuNSAwIDEgMSAwIDlaIi8+PC9zdmc+',
    description: (
      <>
        The structure of the framework is entirely based on Knit with Services and Controllers
      </>
    ),
  },
  {
    title: 'Convenience',
    Svg: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmZmZmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1hcnJvdy1iaWctdXAtZGFzaCI+PHBhdGggZD0iTTkgMTloNiIvPjxwYXRoIGQ9Ik05IDE1di0zSDVsNy03IDcgN2gtNHYzSDl6Ii8+PC9zdmc+',
    description: (
      <>
        Stay focused on coding the features instead of managing the miniscule details
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <img className={styles.featureSvg} role="img" src={Svg}/>
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
