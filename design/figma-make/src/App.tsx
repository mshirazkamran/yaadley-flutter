import { useState } from "react"
import { Icon, type Screen } from "./ui"
import { CalendarScreen, ConnectCalendar, Inbox, Lists, LinkWhatsApp, Today, Welcome } from "./screensCore"
import { Clarify, Clash, Commands, More, Payment, Pending, Settings, Usage } from "./screensMore"

const TABS: { id: Screen; label: string; icon: string }[] = [
  { id: "today", label: "Today", icon: "today" },
  { id: "inbox", label: "Inbox", icon: "inbox" },
  { id: "calendar", label: "Calendar", icon: "cal" },
  { id: "lists", label: "Lists", icon: "list" },
  { id: "more", label: "More", icon: "more" },
]

const GALLERY: { group: string; items: [Screen, string][] }[] = [
  { group: "Onboarding", items: [["welcome", "A1 Welcome"], ["link", "A2 Link WhatsApp"], ["connect", "A3 Connect calendar"]] },
  { group: "Daily", items: [["today", "A4/5 Today · Kal"], ["inbox", "A6 Inbox"], ["pending", "A7 Pending event"], ["clarify", "A8 Clarification"], ["clash", "A9 Clash"], ["calendar", "A10 Calendar"], ["lists", "A11 Lists"]] },
  { group: "Account", items: [["usage", "A12 Usage & plan"], ["payment", "A13 Payment"], ["commands", "A14 Commands"], ["settings", "A15 Settings"], ["more", "More · notifications"]] },
]

const TAB_IDS = TABS.map((t) => t.id)

export default function App() {
  const [screen, setScreen] = useState<Screen>("welcome")
  const [plan, setPlan] = useState("Free")
  const [target, setTarget] = useState("Pro")
  const [banner, setBanner] = useState(true)

  const go = (s: Screen) => setScreen(s)
  const showTabs = TAB_IDS.includes(screen)

  const body = {
    welcome: <Welcome go={go} />,
    link: <LinkWhatsApp go={go} />,
    connect: <ConnectCalendar go={go} />,
    today: <Today go={go} bannerOpen={banner} setBannerOpen={setBanner} />,
    inbox: <Inbox go={go} />,
    calendar: <CalendarScreen />,
    lists: <Lists />,
    more: <More go={go} />,
    pending: <Pending go={go} />,
    clarify: <Clarify go={go} />,
    clash: <Clash go={go} />,
    usage: <Usage go={go} plan={plan} setTarget={setTarget} />,
    payment: <Payment go={go} target={target} onPaid={setPlan} />,
    commands: <Commands go={go} />,
    settings: <Settings go={go} />,
  }[screen]

  return (
    <div className="h-dvh lg:grid lg:grid-cols-[minmax(260px,340px)_1fr] lg:gap-10 lg:px-12 lg:items-center lg:justify-center">
      <aside className="hidden lg:block self-center">
        <p className="label-caps">Yaadly · Android companion</p>
        <h2 className="font-display font-bold text-5xl leading-[0.95] mt-2">App<br />screens</h2>
        <nav className="mt-8 space-y-5" aria-label="Screens">
          {GALLERY.map((g) => (
            <div key={g.group}>
              <p className="label-caps mb-2">{g.group}</p>
              <ul className="flex flex-wrap gap-1.5">
                {g.items.map(([id, label]) => (
                  <li key={label}>
                    <button
                      onClick={() => setScreen(id)}
                      className={`rounded-full px-3 py-1 text-[13px] font-medium border-2 transition-colors ${screen === id ? "bg-ink text-butter border-ink" : "border-ink/20 hover:border-ink hover:bg-butter"}`}
                    >
                      {label}
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </nav>
      </aside>

      <main className="h-full lg:h-[min(840px,94dvh)] lg:w-[410px] lg:justify-self-start flex flex-col bg-cream lg:rounded-[40px] lg:border-2 lg:border-ink lg:shadow-[10px_10px_0_var(--color-ink)] overflow-hidden">
        <div key={screen} className="flex-1 overflow-y-auto scroll-quiet rise">{body}</div>
        {showTabs && (
          <nav className="shrink-0 grid grid-cols-5 border-t-2 border-ink bg-paper px-2 pt-2 pb-3" aria-label="Main">
            {TABS.map((t) => {
              const on = screen === t.id
              return (
                <button key={t.id} onClick={() => go(t.id)} aria-current={on ? "page" : undefined} className="flex flex-col items-center gap-1 text-[11px] font-display font-semibold">
                  <span className={`px-4 py-1 rounded-full transition-colors ${on ? "bg-sun border-2 border-ink -my-0.5 py-[3px]" : "text-clay"}`}>
                    <Icon name={t.icon} size={20} />
                  </span>
                  <span className={on ? "text-ink" : "text-clay"}>{t.label}</span>
                </button>
              )
            })}
          </nav>
        )}
      </main>
    </div>
  )
}
