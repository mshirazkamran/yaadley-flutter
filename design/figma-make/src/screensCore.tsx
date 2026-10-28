import { useEffect, useState } from "react"
import { Btn, Chip, Header, Icon, Segmented, VoicePill, type Go } from "./ui"

/* ---------- A1 Welcome ---------- */
export function Welcome({ go }: { go: Go }) {
  return (
    <div className="min-h-full flex flex-col px-6 pt-10 pb-8 bg-butter relative overflow-hidden">
      <div className="absolute -right-16 -top-16 size-56 rounded-full bg-sun" aria-hidden="true" />
      <p className="label-caps relative">Roman Urdu · WhatsApp · Calendar</p>
      <h1 className="relative font-display font-bold text-[76px] leading-[0.9] mt-3 -ml-1">Yaad<span className="block ml-10">ly</span></h1>
      <p className="relative mt-5 max-w-[16rem] text-[17px] leading-snug">
        Say it in Roman Urdu. <span className="font-semibold">Yaadly remembers.</span>
      </p>

      <div className="relative flex-1 my-8 min-h-[250px]">
        <VoicePill className="absolute left-0 top-2 w-[78%] -rotate-3 rise" />
        <div className="hard absolute right-0 top-[72px] w-[84%] rotate-2 bg-sand rounded-[24px_24px_4px_24px] p-4 rise" style={{ animationDelay: "80ms" }}>
          <p className="text-xs text-clay italic">"mainay kal jana hai 2 bajay ali ki taraf"</p>
          <p className="label-caps mt-3">Kal · 2:00 PM</p>
          <p className="font-display font-bold text-2xl leading-none mt-1">Visit Ali</p>
        </div>
        <div className="hard-sm absolute left-3 bottom-0 bg-paper rounded-full px-4 py-2 -rotate-2 flex items-center gap-2 text-sm font-semibold rise" style={{ animationDelay: "160ms" }}>
          <span>✅</span> Event add ho gaya
        </div>
      </div>

      <Btn onClick={() => go("link")} className="relative w-full text-lg py-4">Shuru karein</Btn>
      <button onClick={() => go("today")} className="relative mt-4 text-sm font-semibold text-clay underline underline-offset-4 hover:text-ink">
        Pehle se account hai?
      </button>
    </div>
  )
}

/* ---------- A2 Link WhatsApp ---------- */
export function LinkWhatsApp({ go }: { go: Go }) {
  const [secs, setSecs] = useState(600)
  const [linked, setLinked] = useState(false)
  const [code, setCode] = useState("482915")
  const expired = secs <= 0 && !linked

  useEffect(() => {
    if (linked || secs <= 0) return
    const t = setInterval(() => setSecs((s) => s - 1), 1000)
    return () => clearInterval(t)
  }, [linked, secs])

  const fresh = () => {
    setCode(String(Math.floor(100000 + Math.random() * 900000)))
    setSecs(600)
  }
  const open = () => setTimeout(() => setLinked(true), 1400)
  const mm = String(Math.floor(secs / 60)).padStart(2, "0")
  const ss = String(secs % 60).padStart(2, "0")

  return (
    <div className="min-h-full pb-8">
      <Header title="WhatsApp link karein" kicker="Step 1 of 2" back="welcome" go={go} />
      <div className="px-5">
        <div className={`hard rounded-[28px_28px_28px_6px] p-5 ${linked ? "bg-sun" : expired ? "bg-sand" : "bg-butter"}`}>
          {linked ? (
            <div className="text-center py-4 rise">
              <span className="mx-auto grid place-items-center size-16 rounded-full bg-ink text-butter"><Icon name="check" size={34} /></span>
              <p className="font-display font-bold text-2xl mt-3">WhatsApp linked</p>
              <p className="text-sm mt-1">+92 300 ••• 4471</p>
            </div>
          ) : (
            <>
              <div className="flex gap-2" aria-label={`Code ${code}`}>
                {code.split("").map((d, i) => (
                  <span
                    key={i}
                    className={`flex-1 grid place-items-center h-16 bg-paper hard-sm rounded-xl font-display font-bold text-3xl ${expired ? "text-tan line-through" : ""} ${i % 2 ? "translate-y-1.5" : ""}`}
                  >
                    {d}
                  </span>
                ))}
              </div>
              <div className="flex items-center justify-between mt-5">
                {expired ? <Chip tone="rust">Code expire ho gaya</Chip> : <Chip tone="ink">Waiting…</Chip>}
                <span className="font-display font-bold text-xl tabular-nums">{mm}:{ss}</span>
              </div>
            </>
          )}
        </div>

        <ol className="mt-8 space-y-4">
          {["Open WhatsApp.", "Yaadly ko ye code bhejein.", "Wapas yahan aayein."].map((s, i) => (
            <li key={s} className="flex items-center gap-4" style={{ marginLeft: i * 14 }}>
              <span className="grid place-items-center size-8 rounded-full bg-ink text-butter font-display font-bold text-sm shrink-0">{i + 1}</span>
              <span className="font-medium">{s}</span>
            </li>
          ))}
        </ol>

        <div className="mt-10 flex flex-col gap-3">
          {linked ? (
            <Btn onClick={() => go("connect")} className="w-full">Aage barhein</Btn>
          ) : (
            <>
              <Btn onClick={open} disabled={expired} className="w-full">WhatsApp kholein</Btn>
              <Btn variant="paper" onClick={fresh} className="w-full">Naya code</Btn>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

/* ---------- A3 Connect calendar ---------- */
export function ConnectCalendar({ go }: { go: Go }) {
  const [state, setState] = useState<"idle" | "connecting" | "connected">("idle")
  const start = () => {
    setState("connecting")
    setTimeout(() => setState("connected"), 1500)
  }
  const perks = ["Events khud add ho jayen", "Clash check pehle se", "Kabhi bina poochay delete nahi"]
  return (
    <div className="min-h-full pb-8">
      <Header title="Calendar connect karein" kicker="Step 2 of 2" back="link" go={go} />
      <div className="px-5">
        <div className="space-y-3">
          {perks.map((p, i) => (
            <div key={p} className={`hard-sm flex items-center gap-3 p-4 ${i === 1 ? "ml-6 bg-sand rounded-[4px_20px_20px_20px]" : "mr-6 bg-butter rounded-[20px_20px_4px_20px]"}`}>
              <Icon name="cal" size={22} />
              <span className="font-medium">{p}</span>
            </div>
          ))}
        </div>

        {state === "connected" && (
          <div className="hard mt-6 bg-sun rounded-2xl p-4 flex items-center gap-3 rise">
            <span className="grid place-items-center size-10 rounded-full bg-ink text-butter"><Icon name="check" /></span>
            <div>
              <p className="font-display font-bold">Google Calendar connected</p>
              <p className="text-sm">ayesha.khan@gmail.com</p>
            </div>
          </div>
        )}

        <div className="mt-10 flex flex-col gap-3 items-stretch">
          {state === "connected" ? (
            <Btn onClick={() => go("today")} className="w-full">Today dekhein</Btn>
          ) : (
            <>
              <Btn onClick={start} disabled={state === "connecting"} className="w-full">
                {state === "connecting" ? "Connecting…" : "Connect Google Calendar"}
              </Btn>
              <button onClick={() => go("today")} className="text-sm font-semibold text-clay underline underline-offset-4 hover:text-ink self-center mt-1">Baad mein</button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

/* ---------- A4/A5 Today & Tomorrow ---------- */
type Ev = { time: string; title: string; meta: string; link?: boolean }
const EVENTS: Record<"aaj" | "kal", Ev[]> = {
  aaj: [
    { time: "9:00", title: "Class: Software Design", meta: "Room 12 · 1h 30m" },
    { time: "1:30", title: "Zuhr + lunch", meta: "Canteen · 45m" },
    { time: "4:00", title: "FYP meeting with Sir Hamza", meta: "Google Meet", link: true },
  ],
  kal: [{ time: "2:00", title: "Visit Ali", meta: "Pending confirm · 1h" }, { time: "6:30", title: "Gym", meta: "Iron Hub · 1h" }],
}

export function Today({ go, bannerOpen, setBannerOpen }: { go: Go; bannerOpen: boolean; setBannerOpen: (v: boolean) => void }) {
  const [day, setDay] = useState<"aaj" | "kal">("aaj")
  const [tasks, setTasks] = useState([
    { t: "Assignment 3 submit karo", done: false },
    { t: "Ammi ko call", done: true },
    { t: "Bijli ka bill", done: false },
  ])
  const events = EVENTS[day]
  return (
    <div className="min-h-full pb-6">
      <Header
        title={day === "aaj" ? "Thursday, 8 Oct" : "Kal"}
        kicker={day === "aaj" ? "Aaj" : "Friday, 9 Oct"}
        right={<Chip tone="sun" className="shrink-0 mb-1">Commands 3/10</Chip>}
      />
      <div className="px-5 flex flex-col gap-5">
        <Segmented options={[{ id: "aaj", label: "Aaj" }, { id: "kal", label: "Kal" }]} value={day} onChange={setDay} />

        {bannerOpen && day === "aaj" && (
          <div className="hard bg-butter rounded-[4px_22px_22px_22px] p-4 flex items-start gap-3 rise">
            <span className="text-rust mt-0.5"><Icon name="warn" /></span>
            <div className="flex-1">
              <p className="font-display font-bold">Clash mila</p>
              <p className="text-sm text-clay">Visit Ali aur FYP meeting overlap kar rahe hain.</p>
              <button onClick={() => go("clash")} className="mt-2 text-sm font-semibold underline underline-offset-4">Dekhein</button>
            </div>
            <button onClick={() => setBannerOpen(false)} aria-label="Dismiss" className="text-clay hover:text-ink"><Icon name="x" size={18} /></button>
          </div>
        )}

        {events.length === 0 ? (
          <p className="text-center text-clay py-10">Aaj kuch plan nahi hai.</p>
        ) : (
          <ul className="flex flex-col gap-3">
            {events.map((e, i) => (
              <li key={e.title} className={`hard flex bg-sand overflow-hidden ${i % 2 ? "ml-5 rounded-[4px_22px_22px_22px]" : "mr-5 rounded-[22px_22px_22px_4px]"}`}>
                <div className="w-[72px] shrink-0 bg-sun border-r-2 border-ink grid place-items-center py-4">
                  <span className="font-display font-bold text-2xl leading-none tabular-nums">{e.time}</span>
                </div>
                <div className="p-3.5 min-w-0">
                  <p className="font-display font-bold leading-tight">{e.title}</p>
                  <p className="text-sm text-clay flex items-center gap-1 mt-1">
                    {e.link && <Icon name="link" size={14} />} {e.meta}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        )}

        <section>
          <p className="label-caps mb-3">Tasks</p>
          <ul className="hard bg-paper rounded-[22px_4px_22px_22px] divide-y-2 divide-ink/10">
            {tasks.map((t, i) => (
              <li key={t.t}>
                <button onClick={() => setTasks(tasks.map((x, j) => (j === i ? { ...x, done: !x.done } : x)))} className="w-full flex items-center gap-3 px-4 py-3.5 text-left">
                  <span className={`size-6 rounded-md border-2 border-ink grid place-items-center shrink-0 ${t.done ? "bg-ink text-butter" : "bg-butter"}`}>
                    {t.done && <Icon name="check" size={16} />}
                  </span>
                  <span className={t.done ? "line-through text-clay" : "font-medium"}>{t.t}</span>
                </button>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  )
}

/* ---------- A6 Inbox ---------- */
type Row = { id: string; emoji: string; title: string; text: string; time: string; unread?: boolean; kind?: "pending" | "clarify" | "clash" }
export function Inbox({ go }: { go: Go }) {
  const [needs, setNeeds] = useState<Row[]>([
    { id: "p", emoji: "✅", title: "Event ready", text: "Visit Ali, kal 2:00 PM", time: "2m", unread: true, kind: "pending" },
    { id: "q", emoji: "❓", title: "Batayein", text: "2 bajay subah ya dopahar?", time: "14m", unread: true, kind: "clarify" },
    { id: "c", emoji: "⚠️", title: "Clash mila", text: "Visit Ali aur FYP meeting overlap", time: "1h", kind: "clash" },
  ])
  const [updates] = useState<Row[]>([
    { id: "u1", emoji: "🛒", title: "Grocery list", text: "5 items add hue", time: "3h" },
    { id: "u2", emoji: "📅", title: "Aaj: 3 events", text: "Pehla: Class 9:00 AM", time: "8:01 AM" },
    { id: "u3", emoji: "✅", title: "WhatsApp linked", text: "Setup mukammal", time: "Kal" },
  ])
  const open = (r: Row) => go(r.kind === "pending" ? "pending" : r.kind === "clash" ? "clash" : "clarify")

  return (
    <div className="min-h-full pb-6">
      <Header title="Inbox" kicker={`${needs.length} need action`} />
      <div className="px-5 space-y-7">
        <section>
          <p className="label-caps mb-3">Needs action</p>
          {needs.length === 0 ? (
            <p className="hard-sm bg-butter rounded-2xl p-5 text-center text-clay">Sab theek hai, kuch pending nahi.</p>
          ) : (
            <ul className="space-y-3">
              {needs.map((r, i) => (
                <li key={r.id} className={`hard bg-butter p-4 ${i % 2 ? "ml-4 rounded-[4px_22px_22px_22px]" : "mr-4 rounded-[22px_22px_22px_4px]"}`}>
                  <button onClick={() => open(r)} className="w-full flex gap-3 text-left">
                    <span className="text-2xl leading-none mt-0.5">{r.emoji}</span>
                    <span className="flex-1 min-w-0">
                      <span className="flex items-center gap-2">
                        <span className="font-display font-bold">{r.title}</span>
                        {r.unread && <span className="size-2 rounded-full bg-rust" aria-label="Unread" />}
                        <span className="ml-auto text-xs text-clay">{r.time}</span>
                      </span>
                      <span className="block text-sm text-clay">{r.text}</span>
                    </span>
                  </button>
                  {r.kind === "pending" && (
                    <div className="flex gap-2 mt-3 pl-9">
                      <button onClick={() => setNeeds(needs.filter((n) => n.id !== r.id))} className="hard-sm press bg-sun rounded-full px-4 py-1.5 text-sm font-display font-semibold">Confirm</button>
                      <button onClick={() => go("pending")} className="hard-sm press bg-paper rounded-full px-4 py-1.5 text-sm font-display font-semibold">Edit</button>
                    </div>
                  )}
                </li>
              ))}
            </ul>
          )}
        </section>

        <section>
          <p className="label-caps mb-3">Updates</p>
          <ul className="hard bg-paper rounded-[22px_4px_22px_22px] divide-y-2 divide-ink/10">
            {updates.map((r) => (
              <li key={r.id} className="flex gap-3 px-4 py-3.5">
                <span className="text-xl">{r.emoji}</span>
                <div className="flex-1 min-w-0">
                  <p className="font-display font-semibold leading-tight">{r.title}</p>
                  <p className="text-sm text-clay">{r.text}</p>
                </div>
                <span className="text-xs text-clay">{r.time}</span>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  )
}

/* ---------- A10 Calendar ---------- */
const EVENT_DAYS: Record<number, { time: string; title: string }[]> = {
  3: [{ time: "11:00", title: "Lab viva" }],
  8: [{ time: "9:00", title: "Class: Software Design" }, { time: "4:00", title: "FYP meeting" }],
  9: [{ time: "2:00", title: "Visit Ali" }, { time: "6:30", title: "Gym" }],
  12: [{ time: "10:00", title: "Dentist" }],
  15: [{ time: "3:00", title: "Sara ki birthday" }],
  21: [{ time: "9:00", title: "Midterm: DB Systems" }],
  27: [{ time: "5:00", title: "Cricket with cousins" }],
}

export function CalendarScreen() {
  const [view, setView] = useState<"day" | "week" | "month">("month")
  const [sel, setSel] = useState(8)
  const [extra, setExtra] = useState<Record<number, { time: string; title: string }[]>>({})
  const [adding, setAdding] = useState(false)
  const [title, setTitle] = useState("")

  const offset = 3 // 1 Oct 2026 is a Thursday (Mon-first grid)
  const cells = [...Array(offset).fill(0), ...Array.from({ length: 31 }, (_, i) => i + 1)]
  const get = (d: number) => [...(EVENT_DAYS[d] ?? []), ...(extra[d] ?? [])]
  const weekStart = sel - ((sel - 1 + offset) % 7)
  const weekDays = Array.from({ length: 7 }, (_, i) => weekStart + i).filter((d) => d >= 1 && d <= 31)

  const add = () => {
    if (!title.trim()) return
    setExtra({ ...extra, [sel]: [...(extra[sel] ?? []), { time: "12:00", title: title.trim() }] })
    setTitle("")
    setAdding(false)
  }

  const DayCell = ({ d }: { d: number }) => (
    <button
      onClick={() => setSel(d)}
      className={`relative aspect-square rounded-xl grid place-items-center font-display font-semibold text-sm transition-colors ${
        sel === d ? "bg-ink text-butter" : d === 8 ? "bg-sun border-2 border-ink" : "hover:bg-sand"
      }`}
    >
      {d}
      {get(d).length > 0 && <span className={`absolute bottom-1.5 size-1.5 rounded-full ${sel === d ? "bg-sun" : "bg-ink"}`} />}
    </button>
  )

  return (
    <div className="min-h-full pb-28 relative">
      <Header title="October" kicker="2026" right={<span className="font-display font-bold text-5xl text-sun leading-none mb-1 [-webkit-text-stroke:2px_var(--color-ink)]">{sel}</span>} />
      <div className="px-5 space-y-5">
        <Segmented options={[{ id: "day", label: "Day" }, { id: "week", label: "Week" }, { id: "month", label: "Month" }]} value={view} onChange={setView} />

        {view === "month" && (
          <div className="hard bg-paper rounded-[26px_26px_26px_6px] p-3">
            <div className="grid grid-cols-7 text-center label-caps mb-1">{["M", "T", "W", "T", "F", "S", "S"].map((d, i) => <span key={i}>{d}</span>)}</div>
            <div className="grid grid-cols-7 gap-y-1">
              {cells.map((d, i) => (d ? <DayCell key={i} d={d} /> : <span key={i} />))}
            </div>
          </div>
        )}
        {view === "week" && (
          <div className="grid grid-cols-7 gap-1.5">
            {weekDays.map((d) => (
              <button key={d} onClick={() => setSel(d)} className={`hard-sm rounded-xl py-3 flex flex-col items-center gap-1 ${sel === d ? "bg-ink text-butter" : "bg-paper"}`}>
                <span className="font-display font-bold">{d}</span>
                <span className="flex gap-0.5">{get(d).map((_, k) => <span key={k} className={`size-1.5 rounded-full ${sel === d ? "bg-sun" : "bg-tan"}`} />)}</span>
              </button>
            ))}
          </div>
        )}

        <section>
          <p className="label-caps mb-3">{sel === 8 ? "Aaj" : `${sel} Oct`}</p>
          {get(sel).length === 0 ? (
            <p className="text-clay py-4">Is din kuch plan nahi.</p>
          ) : (
            <ul className="space-y-2.5">
              {get(sel).map((e, i) => (
                <li key={e.title + i} className="hard-sm bg-sand rounded-[16px_16px_16px_4px] px-4 py-3 flex items-center gap-4">
                  <span className="font-display font-bold tabular-nums w-12">{e.time}</span>
                  <span className="font-medium">{e.title}</span>
                </li>
              ))}
            </ul>
          )}
        </section>

        {adding && (
          <div className="hard bg-butter rounded-2xl p-4 flex gap-2 rise">
            <input
              autoFocus
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && add()}
              placeholder={`Event title (${sel} Oct)`}
              className="flex-1 min-w-0 bg-paper hard-sm rounded-lg px-3 py-2 outline-none"
            />
            <Btn onClick={add} className="!px-4 !py-2">Add</Btn>
          </div>
        )}
      </div>
      <button
        onClick={() => setAdding((a) => !a)}
        aria-label="Event add karein"
        className="hard press sticky bottom-5 mr-5 ml-auto size-14 grid place-items-center bg-sun rounded-[18px_18px_4px_18px]"
      >
        <Icon name={adding ? "x" : "plus"} size={26} />
      </button>
    </div>
  )
}

/* ---------- A11 Lists ---------- */
export function Lists() {
  const [tab, setTab] = useState<"grocery" | "tasks">("grocery")
  const [items, setItems] = useState([
    { t: "Doodh", d: true },
    { t: "Anday", d: false },
    { t: "Chawal", d: false },
    { t: "Cheeni", d: false },
    { t: "Chai", d: false },
  ])
  const [draft, setDraft] = useState("")
  const tasks = [
    { t: "Assignment 3 submit", due: "Aaj", over: false },
    { t: "Library book wapas", due: "2 din pehle", over: true },
    { t: "Passport photos", due: "Sat, 10 Oct", over: false },
  ]
  const add = () => {
    if (!draft.trim()) return
    setItems([...items, { t: draft.trim(), d: false }])
    setDraft("")
  }
  return (
    <div className="min-h-full pb-6">
      <Header title="Lists" kicker="Yaadly ne likha" />
      <div className="px-5 space-y-5">
        <Segmented options={[{ id: "grocery", label: "Grocery" }, { id: "tasks", label: "Tasks" }]} value={tab} onChange={setTab} />
        {tab === "grocery" ? (
          <div className="hard bg-butter rounded-[30px_30px_6px_30px] overflow-hidden">
            <div className="flex items-center gap-3 p-4 bg-sun border-b-2 border-ink">
              <Icon name="basket" size={26} />
              <p className="font-display font-bold text-lg">Grocery list: {items.length} items</p>
            </div>
            <ul>
              {items.map((it, i) => (
                <li key={it.t + i}>
                  <button onClick={() => setItems(items.map((x, j) => (j === i ? { ...x, d: !x.d } : x)))} className="w-full flex items-center gap-3 px-4 py-3 text-left border-b border-ink/10">
                    <span className={`size-6 rounded-md border-2 border-ink grid place-items-center ${it.d ? "bg-ink text-butter" : "bg-paper"}`}>{it.d && <Icon name="check" size={16} />}</span>
                    <span className={it.d ? "line-through text-clay" : "font-medium"}>{it.t}</span>
                  </button>
                </li>
              ))}
            </ul>
            <div className="flex gap-2 p-3">
              <input value={draft} onChange={(e) => setDraft(e.target.value)} onKeyDown={(e) => e.key === "Enter" && add()} placeholder="Item add karein…" className="flex-1 min-w-0 bg-paper hard-sm rounded-full px-4 py-2 outline-none" />
              <button onClick={add} aria-label="Add" className="hard-sm press size-10 grid place-items-center bg-sun rounded-full"><Icon name="plus" /></button>
              <button aria-label="Dictate" className="hard-sm press size-10 grid place-items-center bg-ink text-butter rounded-full"><Icon name="mic" /></button>
            </div>
          </div>
        ) : (
          <ul className="space-y-3">
            {tasks.map((t, i) => (
              <li key={t.t} className={`hard bg-paper p-4 flex items-center justify-between gap-3 ${i % 2 ? "ml-4 rounded-[4px_20px_20px_20px]" : "mr-4 rounded-[20px_20px_20px_4px]"}`}>
                <span className="font-medium">{t.t}</span>
                <Chip tone={t.over ? "rust" : "butter"}>{t.due}</Chip>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
