import { useState } from "react"
import { Btn, Chip, Header, Icon, Segmented, Toggle, VoicePill, type Go, type Screen } from "./ui"

/* ---------- A7 Pending event ---------- */
export function Pending({ go }: { go: Go }) {
  const [f, setF] = useState({ title: "Visit Ali", date: "Fri, 9 Oct 2026", time: "2:00 PM", dur: "1 hour" })
  const [done, setDone] = useState<null | "ok" | "no">(null)
  const fields: [keyof typeof f, string][] = [["title", "Title"], ["date", "Date"], ["time", "Time"], ["dur", "Duration"]]

  if (done)
    return (
      <div className="min-h-full grid place-items-center p-8 text-center">
        <div className="rise">
          <span className={`mx-auto grid place-items-center size-16 rounded-full ${done === "ok" ? "bg-sun" : "bg-sand"} hard`}>
            <Icon name={done === "ok" ? "check" : "x"} size={32} />
          </span>
          <p className="font-display font-bold text-2xl mt-4">{done === "ok" ? "Calendar mein add ho gaya" : "Event discard ho gaya"}</p>
          <Btn onClick={() => go("inbox")} className="mt-6">Inbox par wapas</Btn>
        </div>
      </div>
    )

  return (
    <div className="min-h-full pb-8">
      <Header title="Event ready" kicker="Pending" back="inbox" go={go} />
      <div className="px-5 space-y-5">
        <div className="space-y-3">
          <VoicePill duration="0:07" className="w-[88%]" />
          <p className="hard-sm bg-butter rounded-[4px_18px_18px_18px] p-3.5 text-sm italic ml-6">"mainay kal jana hai 2 bajay ali ki taraf"</p>
        </div>

        <div className="hard bg-sand rounded-[26px_26px_6px_26px] overflow-hidden">
          {fields.map(([k, label]) => (
            <label key={k} className="flex items-center gap-3 px-4 py-3 border-b-2 border-ink/10 last:border-0">
              <span className="label-caps w-20 shrink-0">{label}</span>
              <input
                value={f[k]}
                onChange={(e) => setF({ ...f, [k]: e.target.value })}
                className={`flex-1 min-w-0 bg-transparent outline-none font-display ${k === "title" ? "text-xl font-bold" : "font-semibold"} focus:bg-butter rounded px-1 -mx-1`}
              />
            </label>
          ))}
          <div className="flex items-center gap-3 px-4 py-3 bg-butter">
            <span className="label-caps w-20 shrink-0">Calendar</span>
            <span className="font-semibold">Google · ayesha.khan</span>
          </div>
        </div>
        <p className="text-sm flex items-center gap-2 text-clay"><span className="text-rust"><Icon name="warn" size={16} /></span> Time check kar lein: PM ya AM?</p>

        <div className="grid grid-cols-[1.4fr_1fr_1fr] gap-2.5">
          <Btn onClick={() => setDone("ok")}>Confirm</Btn>
          <Btn variant="paper" onClick={() => document.querySelector<HTMLInputElement>("input")?.focus()}>Edit</Btn>
          <Btn variant="ink" onClick={() => setDone("no")}>Cancel</Btn>
        </div>
      </div>
    </div>
  )
}

/* ---------- A8 Clarification ---------- */
export function Clarify({ go }: { go: Go }) {
  const [ans, setAns] = useState<string | null>(null)
  const [day, setDay] = useState("Kal")
  return (
    <div className="min-h-full pb-8">
      <Header title="Ek sawal" kicker="❓ Needs your input" back="inbox" go={go} />
      <div className="px-5 space-y-6">
        <p className="hard-sm bg-butter rounded-[4px_18px_18px_18px] p-3.5 text-sm italic">"meeting hai 2 bajay"</p>
        <h2 className="font-display font-bold text-[40px] leading-[1.02]">2 bajay <span className="bg-sun px-2 -mx-2 rounded">subah</span> ya dopahar?</h2>
        <div className="grid grid-cols-[1fr_1.25fr] gap-3">
          {["Subah (AM)", "Dopahar (PM)"].map((o) => (
            <button
              key={o}
              onClick={() => setAns(o)}
              className={`hard press font-display font-bold text-xl py-8 rounded-[22px_22px_22px_4px] ${ans === o ? "bg-ink text-butter" : "bg-sun"}`}
            >
              {o}
            </button>
          ))}
        </div>
        <div>
          <p className="label-caps mb-2">Din bhi confirm karein</p>
          <div className="flex gap-2 flex-wrap">
            {["Aaj", "Kal", "Parson", "Date chunein"].map((d) => (
              <button key={d} onClick={() => setDay(d)} className={`hard-sm press rounded-full px-4 py-1.5 text-sm font-display font-semibold ${day === d ? "bg-ink text-butter" : "bg-paper"}`}>{d}</button>
            ))}
          </div>
        </div>
        {ans && (
          <div className="hard bg-sun rounded-2xl p-4 rise">
            <p className="font-display font-bold">{day} · {ans.startsWith("Sub") ? "2:00 AM" : "2:00 PM"}</p>
            <Btn variant="ink" onClick={() => go("pending")} className="mt-3 w-full">Aage barhein</Btn>
          </div>
        )}
      </div>
    </div>
  )
}

/* ---------- A9 Clash ---------- */
export function Clash({ go }: { go: Go }) {
  const [slots, setSlots] = useState(false)
  const [slot, setSlot] = useState<string | null>(null)
  return (
    <div className="min-h-full pb-8">
      <Header title="Clash mil gaya" kicker="⚠️ Overlap" back="today" go={go} />
      <div className="px-5 space-y-5">
        <div className="relative pb-2">
          <div className="hard bg-butter rounded-[24px_24px_24px_4px] p-4 mr-8">
            <Chip tone="sun">New</Chip>
            <p className="font-display font-bold text-2xl mt-2">Visit Ali</p>
            <p className="text-sm text-clay">Fri · 3:30 – 4:30 PM</p>
          </div>
          <div className="hard bg-sand rounded-[4px_24px_24px_24px] p-4 ml-8 -mt-1 rotate-[0.8deg]">
            <Chip tone="ink">Existing</Chip>
            <p className="font-display font-bold text-2xl mt-2">FYP meeting</p>
            <p className="text-sm text-clay">Fri · 4:00 – 5:00 PM</p>
          </div>
        </div>
        <div className="flex flex-col gap-3">
          <Btn onClick={() => go("today")}>Dono rakho</Btn>
          <Btn variant="paper" onClick={() => setSlots(true)}>Time badlo</Btn>
          <Btn variant="ink" onClick={() => go("inbox")}>Naya cancel karo</Btn>
        </div>
        {slots && (
          <div className="rise">
            <p className="label-caps mb-2">Khali slots</p>
            <div className="flex gap-2 flex-wrap">
              {["2:00 PM", "5:00 PM", "6:30 PM"].map((s) => (
                <button key={s} onClick={() => setSlot(s)} className={`hard-sm press rounded-full px-4 py-2 font-display font-semibold ${slot === s ? "bg-ink text-butter" : "bg-sun"}`}>{s}</button>
              ))}
            </div>
            {slot && <p className="mt-3 text-sm">Visit Ali ab <b>{slot}</b> par move hoga. <button onClick={() => go("today")} className="font-semibold underline underline-offset-4">Confirm</button></p>}
          </div>
        )}
      </div>
    </div>
  )
}

/* ---------- More ---------- */
export function More({ go }: { go: Go }) {
  const rows: { id: Screen; t: string; s: string }[] = [
    { id: "usage", t: "Usage aur plan", s: "Free · 3/10 commands" },
    { id: "commands", t: "Commands aur help", s: "/today, /tomorrow aur baqi" },
    { id: "settings", t: "Settings", s: "Language, reminders, privacy" },
  ]
  const notifs = [
    ["Aaj: 3 events", "Pehla: Class 9:00 AM"],
    ["Reminder", "30 minute mein: Visit Ali"],
    ["Limit poori", "Aaj ki commands khatam. Kal reset hongi"],
  ]
  return (
    <div className="min-h-full pb-6">
      <Header title="More" kicker="Ayesha Khan" />
      <div className="px-5 space-y-7">
        <ul className="space-y-3">
          {rows.map((r, i) => (
            <li key={r.id}>
              <button onClick={() => go(r.id)} className={`hard press w-full flex items-center justify-between text-left p-4 bg-butter ${i % 2 ? "ml-4 w-[calc(100%-1rem)] rounded-[4px_20px_20px_20px]" : "rounded-[20px_20px_20px_4px]"}`}>
                <span>
                  <span className="block font-display font-bold text-lg">{r.t}</span>
                  <span className="text-sm text-clay">{r.s}</span>
                </span>
                <Icon name="chev" />
              </button>
            </li>
          ))}
        </ul>
        <section>
          <p className="label-caps mb-3">Notifications aise dikhti hain</p>
          <div className="space-y-2.5">
            {notifs.map(([t, b], i) => (
              <div key={t} className={`hard-sm flex gap-3 items-center bg-paper rounded-2xl p-3 ${i === 1 ? "ml-5" : ""}`}>
                <span className="size-9 grid place-items-center rounded-lg bg-sun shrink-0"><Icon name="bolt" size={18} /></span>
                <div className="min-w-0">
                  <p className="font-display font-bold text-sm leading-tight">{t}</p>
                  <p className="text-sm text-clay truncate">{b}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  )
}

/* ---------- A12 Usage & plan ---------- */
export const PLANS = [
  { id: "Free", price: "Rs 0", limit: "10 commands/din", n: 0 },
  { id: "Pro", price: "Rs 700", limit: "4 replies/din", n: 700 },
  { id: "Max", price: "Rs 2,000", limit: "8 replies/din", n: 2000 },
  { id: "Special", price: "Rs 6,000", limit: "Unlimited replies", n: 6000 },
]

function Bar({ label, v, max }: { label: string; v: number; max: number }) {
  return (
    <div>
      <div className="flex justify-between font-display font-semibold text-sm mb-1.5"><span>{label}</span><span className="tabular-nums">{v}/{max}</span></div>
      <div className="h-5 hard-sm bg-paper rounded-full overflow-hidden">
        <div className="h-full bg-sun border-r-2 border-ink" style={{ width: `${(v / max) * 100}%` }} />
      </div>
    </div>
  )
}

export function Usage({ go, plan, setTarget }: { go: Go; plan: string; setTarget: (p: string) => void }) {
  return (
    <div className="min-h-full pb-8">
      <Header title="Usage" kicker="Aaj" back="more" go={go} />
      <div className="px-5 space-y-6">
        <div className="hard bg-butter rounded-[26px_26px_6px_26px] p-5 space-y-4">
          <Bar label="Commands" v={3} max={10} />
          <Bar label="Replies" v={plan === "Free" ? 0 : 2} max={plan === "Free" ? 1 : plan === "Pro" ? 4 : 8} />
          <p className="text-sm text-clay">Kal subah 12:00 baje reset</p>
        </div>
        <div className="flex items-center justify-between hard bg-ink text-butter rounded-[4px_22px_22px_22px] p-4">
          <div>
            <p className="label-caps !text-tan">Current plan</p>
            <p className="font-display font-bold text-2xl">{plan}</p>
          </div>
          <Btn onClick={() => { setTarget("Pro"); go("payment") }} className="!bg-sun">Upgrade</Btn>
        </div>
        <ul className="space-y-2.5">
          {PLANS.map((p, i) => (
            <li key={p.id}>
              <button
                onClick={() => { if (p.id !== plan) { setTarget(p.id); go("payment") } }}
                className={`hard-sm w-full flex items-center justify-between p-4 text-left ${p.id === plan ? "bg-sun" : "bg-paper"} ${i % 2 ? "rounded-[16px_16px_16px_4px]" : "rounded-[4px_16px_16px_16px]"}`}
              >
                <span>
                  <span className="block font-display font-bold text-lg">{p.id}</span>
                  <span className="text-sm text-clay">{p.limit}</span>
                </span>
                <span className="font-display font-bold">{p.price}<span className="text-xs font-medium text-clay">{p.n ? "/mo" : ""}</span></span>
              </button>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}

/* ---------- A13 Payment ---------- */
export function Payment({ go, target, onPaid }: { go: Go; target: string; onPaid: (p: string) => void }) {
  const [method, setMethod] = useState("JazzCash")
  const [state, setState] = useState<"idle" | "processing" | "success">("idle")
  const plan = PLANS.find((p) => p.id === target) ?? PLANS[1]
  const pay = () => {
    setState("processing")
    setTimeout(() => {
      setState("success")
      onPaid(plan.id)
    }, 1600)
  }
  if (state === "success")
    return (
      <div className="min-h-full grid place-items-center p-8 text-center">
        <div className="rise">
          <span className="mx-auto grid place-items-center size-20 rounded-full bg-sun hard"><Icon name="check" size={40} /></span>
          <p className="font-display font-bold text-3xl mt-4">Plan active ho gaya</p>
          <p className="text-clay mt-1">{plan.id} · {plan.limit}</p>
          <Btn onClick={() => go("usage")} className="mt-6">Theek hai</Btn>
        </div>
      </div>
    )
  return (
    <div className="min-h-full pb-8">
      <Header title="Payment" kicker="Plan badlein" back="usage" go={go} />
      <div className="px-5 space-y-6">
        <div className="hard bg-butter rounded-[26px_26px_26px_6px] p-5 flex justify-between items-end">
          <div>
            <p className="label-caps">Plan</p>
            <p className="font-display font-bold text-3xl">{plan.id}</p>
            <p className="text-sm text-clay">{plan.limit}</p>
          </div>
          <p className="font-display font-bold text-2xl">{plan.price}</p>
        </div>
        <div>
          <p className="label-caps mb-2">Payment method</p>
          <div className="grid grid-cols-2 gap-2.5">
            {["JazzCash", "Easypaisa", "Bank transfer", "Card"].map((m, i) => (
              <button key={m} onClick={() => setMethod(m)} className={`hard-sm press p-3.5 font-display font-semibold text-left ${method === m ? "bg-ink text-butter" : "bg-paper"} ${i % 3 === 0 ? "rounded-[14px_14px_14px_4px]" : "rounded-[4px_14px_14px_14px]"}`}>{m}</button>
            ))}
          </div>
        </div>
        <div className="flex justify-between font-display font-bold text-xl border-t-2 border-ink pt-4"><span>Total</span><span>{plan.price}</span></div>
        <Btn onClick={pay} disabled={state === "processing"} className="w-full text-lg py-4">{state === "processing" ? "Processing…" : "Pay now"}</Btn>
      </div>
    </div>
  )
}

/* ---------- A14 Commands ---------- */
export function Commands({ go }: { go: Go }) {
  const [copied, setCopied] = useState<string | null>(null)
  const cmds = [
    ["/today", "Aaj ke events aur tasks"],
    ["/tomorrow", "Kal ka plan"],
    ["/calendar", "Hafte ya mahine ka view"],
    ["/list", "Grocery list kholein"],
    ["/tasks", "Tasks aur due dates"],
    ["/plan", "Usage aur limits"],
    ["/help", "Ye screen"],
  ]
  const examples = [
    "mainay kal jana hai 2 bajay ali ki taraf",
    "doodh, anday, chawal, cheeni aur chai lena hai",
    "meeting hai kal 3 pm",
    "kal wali meeting 4 bajay kar do",
  ]
  const reactions = [["👀", "Process ho raha hai"], ["✅", "Save ho gaya"], ["📅", "Command ready"], ["⚠️", "Clash mila"], ["❓", "Aap ka input chahiye"], ["🛒", "List update"], ["❌", "Samajh nahi aya"]]
  const copy = (c: string) => {
    navigator.clipboard?.writeText(c)
    setCopied(c)
    setTimeout(() => setCopied(null), 1200)
  }
  return (
    <div className="min-h-full pb-8">
      <Header title="Commands" kicker="Help" back="more" go={go} />
      <div className="px-5 space-y-8">
        <ul className="space-y-2.5">
          {cmds.map(([c, d], i) => (
            <li key={c} className={`hard-sm flex items-center gap-3 bg-sand p-3 ${i % 2 ? "ml-4 rounded-[4px_16px_16px_16px]" : "mr-4 rounded-[16px_16px_16px_4px]"}`}>
              <div className="flex-1 min-w-0">
                <code className="font-display font-bold text-lg">{c}</code>
                <p className="text-sm text-clay">{d}</p>
              </div>
              <button onClick={() => copy(c)} className="hard-sm press bg-paper rounded-full px-3 py-1.5 text-xs font-display font-semibold flex items-center gap-1">
                <Icon name="copy" size={14} /> {copied === c ? "Copied" : "Copy"}
              </button>
            </li>
          ))}
        </ul>
        <section>
          <p className="label-caps mb-3">Voice note examples</p>
          <div className="space-y-2.5">
            {examples.map((e, i) => (
              <p key={e} className={`hard-sm bg-butter p-3.5 text-sm italic ${i % 2 ? "ml-6 rounded-[4px_18px_18px_18px]" : "mr-6 rounded-[18px_18px_18px_4px]"}`}>"{e}"</p>
            ))}
          </div>
        </section>
        <section>
          <p className="label-caps mb-3">Reaction guide</p>
          <ul className="hard bg-paper rounded-[22px_4px_22px_22px] divide-y-2 divide-ink/10">
            {reactions.map(([e, t]) => (
              <li key={e} className="flex items-center gap-4 px-4 py-2.5"><span className="text-xl w-7">{e}</span><span className="text-sm font-medium">{t}</span></li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  )
}

/* ---------- A15 Settings ---------- */
export function Settings({ go }: { go: Go }) {
  const [pref, setPref] = useState<"chat" | "app">("app")
  const [auto, setAuto] = useState(false)
  const [quiet, setQuiet] = useState(true)
  const [confirmDel, setConfirmDel] = useState(false)
  const rows = [["Language", "Roman Urdu"], ["Timezone", "Asia/Karachi"], ["Reminder time", "30 min pehle"], ["Quiet hours", "11 PM – 7 AM"], ["Calendar", "Google · connected"], ["WhatsApp", "Linked · +92 300 ••• 4471"]]
  return (
    <div className="min-h-full pb-8 relative">
      <Header title="Settings" kicker="Aap ka Yaadly" back="more" go={go} />
      <div className="px-5 space-y-6">
        <div>
          <p className="label-caps mb-2">Reply preference</p>
          <Segmented options={[{ id: "chat", label: "Chat replies" }, { id: "app", label: "App only" }]} value={pref} onChange={setPref} />
          <p className="text-sm text-clay mt-2">{pref === "app" ? "Reactions + app notifications. Koi reply kharch nahi." : "Bot WhatsApp par reply karega (daily limit tak)."}</p>
        </div>
        <ul className="hard bg-paper rounded-[26px_26px_6px_26px] divide-y-2 divide-ink/10">
          <li className="flex items-center justify-between px-4 py-3.5"><span className="font-medium">Auto-save events</span><Toggle on={auto} onChange={setAuto} label="Auto-save events" /></li>
          <li className="flex items-center justify-between px-4 py-3.5"><span className="font-medium">Quiet hours</span><Toggle on={quiet} onChange={setQuiet} label="Quiet hours" /></li>
          {rows.map(([k, v]) => (
            <li key={k} className="flex items-center justify-between px-4 py-3.5 gap-3"><span className="font-medium">{k}</span><span className="text-sm text-clay text-right">{v}</span></li>
          ))}
        </ul>
        <button onClick={() => setConfirmDel(true)} className="hard-sm press w-full bg-paper text-rust font-display font-bold py-3 rounded-[4px_14px_14px_14px]">Delete my data</button>
        <p className="text-center text-sm text-clay underline underline-offset-4">About aur privacy</p>
      </div>
      {confirmDel && (
        <div className="absolute inset-0 z-10 bg-ink/50 grid place-items-center p-6" role="dialog" aria-modal="true">
          <div className="hard bg-cream rounded-[24px_24px_24px_4px] p-5 rise">
            <p className="font-display font-bold text-xl leading-snug">Kya aap sach mein sara data delete karna chahte hain?</p>
            <div className="grid grid-cols-2 gap-2.5 mt-5">
              <Btn variant="ink" onClick={() => { setConfirmDel(false); go("welcome") }}>Haan, delete karo</Btn>
              <Btn variant="paper" onClick={() => setConfirmDel(false)}>Nahi</Btn>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
