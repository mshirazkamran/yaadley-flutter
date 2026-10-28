import type { ReactNode } from "react"

export type Screen =
  | "welcome"
  | "link"
  | "connect"
  | "today"
  | "inbox"
  | "calendar"
  | "lists"
  | "more"
  | "pending"
  | "clarify"
  | "clash"
  | "usage"
  | "payment"
  | "commands"
  | "settings"

export type Go = (s: Screen) => void

const paths: Record<string, string> = {
  mic: "M12 14a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v5a3 3 0 0 0 3 3Zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.92V21h2v-3.08A7 7 0 0 0 19 11h-2Z",
  cal: "M7 2v2H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2h-2V2h-2v2H9V2H7Zm9.7 8.7-5 5a1 1 0 0 1-1.4 0l-2-2 1.4-1.4 1.3 1.3 4.3-4.3 1.4 1.4Z",
  check: "M9.5 16.2 5.3 12l-1.4 1.4 5.6 5.6L21 7.4 19.6 6 9.5 16.2Z",
  basket: "M5.5 9 9 3h2L8 9h8l-3-6h2l3.5 6H22v2h-1l-1.6 9a2 2 0 0 1-2 1.6H6.6a2 2 0 0 1-2-1.6L3 11H2V9h3.5ZM9 13v5h2v-5H9Zm4 0v5h2v-5h-2Z",
  link: "M10.6 13.4a1 1 0 0 1 0-1.4l3-3a3 3 0 0 1 4.2 4.2l-2 2-1.4-1.4 2-2a1 1 0 0 0-1.4-1.4l-3 3a1 1 0 0 1-1.4 0ZM13.4 10.6a1 1 0 0 1 0 1.4l-3 3a3 3 0 0 1-4.2-4.2l2-2 1.4 1.4-2 2a1 1 0 0 0 1.4 1.4l3-3a1 1 0 0 1 1.4 0Z",
  play: "M8 5v14l11-7L8 5Z",
  plus: "M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6V5Z",
  back: "M15.4 5.6 9 12l6.4 6.4-1.4 1.4L6.2 12 14 4.2l1.4 1.4Z",
  chev: "M8.6 5.6 15 12l-6.4 6.4 1.4 1.4L17.8 12 10 4.2 8.6 5.6Z",
  today: "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm1 5v5.4l3.7 2.2-1 1.7L11 13V7h2Z",
  inbox: "M4 4h16a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1Zm1 11v3h14v-3h-4a3 3 0 0 1-6 0H5Z",
  list: "M4 6h2v2H4V6Zm4 0h12v2H8V6Zm-4 5h2v2H4v-2Zm4 0h12v2H8v-2Zm-4 5h2v2H4v-2Zm4 0h12v2H8v-2Z",
  more: "M5 10a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm7 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm7 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4Z",
  warn: "M12 3 1.5 21h21L12 3Zm-1 7h2v5h-2v-5Zm0 6.5h2v2h-2v-2Z",
  copy: "M8 3h11a2 2 0 0 1 2 2v12h-2V5H8V3ZM5 7h10a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2Z",
  x: "m6.4 5 5.6 5.6L17.6 5 19 6.4 13.4 12l5.6 5.6-1.4 1.4-5.6-5.6L6.4 19 5 17.6l5.6-5.6L5 6.4 6.4 5Z",
  bolt: "M13 2 4 14h6l-1 8 9-12h-6l1-8Z",
}

export function Icon({ name, size = 20, className = "" }: { name: keyof typeof paths | string; size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d={paths[name]} />
    </svg>
  )
}

export function Btn({
  children,
  onClick,
  variant = "sun",
  className = "",
  disabled,
}: {
  children: ReactNode
  onClick?: () => void
  variant?: "sun" | "ink" | "paper"
  className?: string
  disabled?: boolean
}) {
  const v = {
    sun: "bg-sun text-ink",
    ink: "bg-ink text-butter",
    paper: "bg-paper text-ink",
  }[variant]
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`hard press font-display font-semibold text-[15px] px-5 py-3 rounded-[14px_14px_14px_4px] disabled:opacity-50 ${v} ${className}`}
    >
      {children}
    </button>
  )
}

export function Chip({ children, tone = "butter", className = "" }: { children: ReactNode; tone?: "butter" | "sand" | "sun" | "rust" | "ink"; className?: string }) {
  const t = {
    butter: "bg-butter text-ink",
    sand: "bg-sand text-ink",
    sun: "bg-sun text-ink",
    rust: "bg-rust text-paper",
    ink: "bg-ink text-butter",
  }[tone]
  return <span className={`hard-sm inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold ${t} ${className}`}>{children}</span>
}

const WAVE = [6, 12, 8, 16, 10, 20, 14, 8, 18, 12, 6, 14, 20, 10, 16, 8, 12, 6, 10, 14]

export function VoicePill({ duration = "0:07", className = "" }: { duration?: string; className?: string }) {
  return (
    <div className={`hard-sm flex items-center gap-3 bg-paper rounded-full pl-2 pr-4 py-2 ${className}`}>
      <span className="grid place-items-center size-9 rounded-full bg-ink text-butter shrink-0">
        <Icon name="play" size={16} />
      </span>
      <div className="flex items-center gap-[2px] flex-1 h-6" aria-hidden="true">
        {WAVE.map((h, i) => (
          <span key={i} className={`w-[3px] rounded-full ${i % 3 === 0 ? "bg-tan" : "bg-ink"}`} style={{ height: h }} />
        ))}
      </div>
      <span className="text-xs font-semibold tabular-nums text-clay">{duration}</span>
    </div>
  )
}

export function Header({ title, kicker, back, go, right }: { title: string; kicker?: string; back?: Screen; go?: Go; right?: ReactNode }) {
  return (
    <header className="px-5 pt-6 pb-4 flex items-end justify-between gap-3">
      <div className="min-w-0">
        {back && go && (
          <button onClick={() => go(back)} className="flex items-center gap-1 text-sm font-semibold text-clay mb-2 -ml-1 hover:text-ink">
            <Icon name="back" size={18} /> Wapas
          </button>
        )}
        {kicker && <p className="label-caps mb-1">{kicker}</p>}
        <h1 className="text-[34px] leading-[1.02] font-bold">{title}</h1>
      </div>
      {right}
    </header>
  )
}

export function Segmented<T extends string>({ options, value, onChange }: { options: { id: T; label: string }[]; value: T; onChange: (v: T) => void }) {
  return (
    <div className="hard-sm inline-flex bg-sand rounded-full p-1 gap-1" role="tablist">
      {options.map((o) => (
        <button
          key={o.id}
          role="tab"
          aria-selected={value === o.id}
          onClick={() => onChange(o.id)}
          className={`px-4 py-1.5 rounded-full text-sm font-display font-semibold transition-colors ${value === o.id ? "bg-ink text-butter" : "text-clay hover:text-ink"}`}
        >
          {o.label}
        </button>
      ))}
    </div>
  )
}

export function Toggle({ on, onChange, label }: { on: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <button
      role="switch"
      aria-checked={on}
      aria-label={label}
      onClick={() => onChange(!on)}
      className={`hard-sm relative w-12 h-7 rounded-full transition-colors ${on ? "bg-sun" : "bg-sand"}`}
    >
      <span className={`absolute top-[2px] size-5 rounded-full bg-ink transition-all ${on ? "left-[22px]" : "left-[2px]"}`} />
    </button>
  )
}
