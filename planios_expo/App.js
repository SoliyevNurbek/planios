import AsyncStorage from '@react-native-async-storage/async-storage';
import { StatusBar } from 'expo-status-bar';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Alert,
  Modal,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';

const STORAGE_KEY = 'planios_expo.tasks';
const ONBOARDING_KEY = 'planios_expo.onboarding';

const theme = {
  bg: '#F4F1E8',
  card: '#FFFFFF',
  green: '#1F8A5B',
  greenDark: '#145A3D',
  mint: '#8CE0BB',
  text: '#17201B',
  muted: '#647067',
  amber: '#D89B2B',
  border: '#E7E0D1',
  danger: '#B64545',
};

const priorities = ['Low', 'Medium', 'High'];
const repeatTypes = ['None', 'Daily', 'Weekly'];
const tabs = ['Home', 'Tasks', 'Stats', 'Settings'];
const focusMessages = [
  'One focused block moves the day forward.',
  'Protect the next few minutes. They matter.',
  'Discipline compounds faster than motivation.',
  'Finish the block before switching context.',
  'Momentum comes from completion, not juggling.',
];

function formatDate(date) {
  return new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric' }).format(date);
}

function formatWeekday(date) {
  return new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(date);
}

function formatDateInput(date) {
  return date.toISOString().slice(0, 10);
}

function parseDateInput(value) {
  const parts = value.split('-').map(Number);
  if (parts.length !== 3 || parts.some(Number.isNaN)) {
    return new Date();
  }
  return new Date(parts[0], parts[1] - 1, parts[2]);
}

function formatTime(totalMinutes) {
  const normalized = ((totalMinutes % 1440) + 1440) % 1440;
  const hours = String(Math.floor(normalized / 60)).padStart(2, '0');
  const minutes = String(normalized % 60).padStart(2, '0');
  return `${hours}:${minutes}`;
}

function parseTimeInput(value) {
  const parts = value.split(':').map(Number);
  if (parts.length !== 2 || parts.some(Number.isNaN)) {
    return 9 * 60;
  }
  return Math.max(0, Math.min(23 * 60 + 59, parts[0] * 60 + parts[1]));
}

function isSameDay(left, right) {
  return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
}

function isTomorrow(taskDate, now) {
  const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
  return isSameDay(taskDate, tomorrow);
}

function weekBounds(now) {
  const day = now.getDay();
  const normalized = day === 0 ? 6 : day - 1;
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - normalized);
  const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 7);
  return { start, end };
}

function taskInCurrentWeek(taskDate, now) {
  const { start, end } = weekBounds(now);
  return taskDate >= start && taskDate < end;
}

function taskDurationMinutes(task) {
  let end = task.endMinutes;
  if (end <= task.startMinutes) {
    end += 1440;
  }
  return Math.max(1, end - task.startMinutes);
}

function buildSeedTasks() {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);

  return [
    {
      id: 'task-morning-workout',
      title: 'Morning workout',
      description: 'Start the day with an energizing 45-minute session.',
      date: today.toISOString(),
      startMinutes: 8 * 60 + 30,
      endMinutes: 9 * 60 + 15,
      priority: 'Medium',
      repeatType: 'Daily',
      isCompleted: false,
    },
    {
      id: 'task-deep-work',
      title: 'Deep work block',
      description: 'Ship one meaningful task with notifications off.',
      date: today.toISOString(),
      startMinutes: 10 * 60,
      endMinutes: 11 * 60 + 30,
      priority: 'High',
      repeatType: 'None',
      isCompleted: false,
    },
    {
      id: 'task-plan-tomorrow',
      title: 'Plan tomorrow',
      description: 'Set the top three outcomes before the day ends.',
      date: tomorrow.toISOString(),
      startMinutes: 19 * 60,
      endMinutes: 19 * 60 + 30,
      priority: 'Low',
      repeatType: 'Daily',
      isCompleted: false,
    },
  ];
}

function sortTasks(list) {
  const rank = { High: 1, Medium: 2, Low: 3 };
  return [...list].sort((a, b) => {
    const dateDiff = new Date(a.date) - new Date(b.date);
    if (dateDiff !== 0) return dateDiff;
    if (a.isCompleted !== b.isCompleted) return a.isCompleted ? 1 : -1;
    if (rank[a.priority] !== rank[b.priority]) return rank[a.priority] - rank[b.priority];
    return a.startMinutes - b.startMinutes;
  });
}

function completionRateFor(tasks, date) {
  const target = tasks.filter((task) => isSameDay(new Date(task.date), date));
  if (!target.length) return 0;
  return target.filter((task) => task.isCompleted).length / target.length;
}

function currentStreak(tasks) {
  let streak = 0;
  let cursor = new Date();
  cursor = new Date(cursor.getFullYear(), cursor.getMonth(), cursor.getDate());

  while (true) {
    const dayTasks = tasks.filter((task) => isSameDay(new Date(task.date), cursor));
    if (!dayTasks.length || dayTasks.some((task) => !task.isCompleted)) {
      break;
    }
    streak += 1;
    cursor = new Date(cursor.getFullYear(), cursor.getMonth(), cursor.getDate() - 1);
  }

  return streak;
}

function weeklyData(tasks) {
  const now = new Date();
  return Array.from({ length: 7 }, (_, index) => {
    const date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (6 - index));
    return {
      label: index === 6 ? 'Today' : formatWeekday(date),
      completionRate: completionRateFor(tasks, date),
      date,
    };
  });
}

function ProgressBar({ progress }) {
  return (
    <View style={styles.progressTrack}>
      <View style={[styles.progressFill, { width: `${Math.max(0, Math.min(progress, 1)) * 100}%` }]} />
    </View>
  );
}

function Card({ children, style }) {
  return <View style={[styles.card, style]}>{children}</View>;
}

function Chip({ label, active, onPress }) {
  return (
    <Pressable onPress={onPress} style={[styles.chip, active && styles.chipActive]}>
      <Text style={[styles.chipText, active && styles.chipTextActive]}>{label}</Text>
    </Pressable>
  );
}

function MetricCard({ title, value, caption }) {
  return (
    <Card style={styles.metricCard}>
      <Text style={styles.metricTitle}>{title}</Text>
      <Text style={styles.metricValue}>{value}</Text>
      <Text style={styles.metricCaption}>{caption}</Text>
    </Card>
  );
}

function TaskRow({ task, onToggle, onEdit, onDelete, onFocus }) {
  return (
    <Card style={styles.taskCard}>
      <View style={styles.taskTop}>
        <Pressable onPress={onToggle} style={[styles.checkbox, task.isCompleted && styles.checkboxChecked]}>
          {task.isCompleted ? <Text style={styles.checkboxMark}>?</Text> : null}
        </Pressable>
        <Pressable style={styles.taskMain} onPress={onEdit}>
          <Text style={[styles.taskTitle, task.isCompleted && styles.taskTitleDone]}>{task.title}</Text>
          <Text style={styles.taskMeta}>{`${formatDate(new Date(task.date))} • ${formatTime(task.startMinutes)} - ${formatTime(task.endMinutes)}`}</Text>
          {!!task.description && <Text style={styles.taskDescription}>{task.description}</Text>}
        </Pressable>
      </View>
      <View style={styles.taskFooter}>
        <View style={styles.tagRow}>
          <Text style={styles.tag}>{task.priority}</Text>
          <Text style={styles.tag}>{task.repeatType}</Text>
          <Text style={styles.tag}>{`${taskDurationMinutes(task)} min`}</Text>
        </View>
        <View style={styles.inlineActions}>
          <Pressable onPress={onFocus} style={styles.inlineButton}><Text style={styles.inlineButtonText}>Focus</Text></Pressable>
          <Pressable onPress={onDelete} style={[styles.inlineButton, styles.inlineButtonDanger]}><Text style={styles.inlineButtonDangerText}>Delete</Text></Pressable>
        </View>
      </View>
    </Card>
  );
}

function TaskEditor({ visible, task, onClose, onSave }) {
  const [form, setForm] = useState(null);

  useEffect(() => {
    if (visible) {
      const targetDate = task?.date ? new Date(task.date) : new Date();
      setForm({
        id: task?.id,
        title: task?.title ?? '',
        description: task?.description ?? '',
        date: formatDateInput(targetDate),
        startTime: formatTime(task?.startMinutes ?? 540),
        endTime: formatTime(task?.endMinutes ?? 585),
        priority: task?.priority ?? 'Medium',
        repeatType: task?.repeatType ?? 'None',
        isCompleted: task?.isCompleted ?? false,
      });
    }
  }, [visible, task]);

  if (!visible || !form) return null;

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalBackdrop}>
        <View style={styles.modalSheet}>
          <Text style={styles.modalTitle}>{task ? 'Edit Task' : 'New Task'}</Text>
          <ScrollView showsVerticalScrollIndicator={false}>
            <TextInput value={form.title} onChangeText={(value) => setForm({ ...form, title: value })} placeholder="Title" style={styles.input} placeholderTextColor={theme.muted} />
            <TextInput value={form.description} onChangeText={(value) => setForm({ ...form, description: value })} placeholder="Description" style={[styles.input, styles.textArea]} placeholderTextColor={theme.muted} multiline />
            <TextInput value={form.date} onChangeText={(value) => setForm({ ...form, date: value })} placeholder="YYYY-MM-DD" style={styles.input} placeholderTextColor={theme.muted} />
            <View style={styles.doubleRow}>
              <TextInput value={form.startTime} onChangeText={(value) => setForm({ ...form, startTime: value })} placeholder="HH:MM" style={[styles.input, styles.halfInput]} placeholderTextColor={theme.muted} />
              <TextInput value={form.endTime} onChangeText={(value) => setForm({ ...form, endTime: value })} placeholder="HH:MM" style={[styles.input, styles.halfInput]} placeholderTextColor={theme.muted} />
            </View>
            <Text style={styles.fieldLabel}>Priority</Text>
            <View style={styles.chipRow}>{priorities.map((item) => <Chip key={item} label={item} active={form.priority === item} onPress={() => setForm({ ...form, priority: item })} />)}</View>
            <Text style={styles.fieldLabel}>Repeat</Text>
            <View style={styles.chipRow}>{repeatTypes.map((item) => <Chip key={item} label={item} active={form.repeatType === item} onPress={() => setForm({ ...form, repeatType: item })} />)}</View>
            <View style={styles.switchRow}>
              <Text style={styles.switchLabel}>Mark as completed</Text>
              <Switch value={form.isCompleted} onValueChange={(value) => setForm({ ...form, isCompleted: value })} trackColor={{ true: theme.green }} />
            </View>
          </ScrollView>
          <View style={styles.modalActions}>
            <Pressable onPress={onClose} style={[styles.actionButton, styles.secondaryButton]}><Text style={styles.secondaryButtonText}>Cancel</Text></Pressable>
            <Pressable
              onPress={() => {
                if (!form.title.trim()) {
                  Alert.alert('Title required', 'Please enter a task title.');
                  return;
                }
                onSave({
                  id: form.id ?? String(Date.now()),
                  title: form.title.trim(),
                  description: form.description.trim(),
                  date: parseDateInput(form.date).toISOString(),
                  startMinutes: parseTimeInput(form.startTime),
                  endMinutes: parseTimeInput(form.endTime),
                  priority: form.priority,
                  repeatType: form.repeatType,
                  isCompleted: form.isCompleted,
                });
              }}
              style={styles.actionButton}
            >
              <Text style={styles.actionButtonText}>Save Task</Text></Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}
function FocusModal({ task, visible, onClose, onComplete }) {
  const [remaining, setRemaining] = useState(0);
  const [isRunning, setIsRunning] = useState(true);
  const [message, setMessage] = useState(focusMessages[0]);
  const intervalRef = useRef(null);

  useEffect(() => {
    if (!visible || !task) return undefined;
    const total = taskDurationMinutes(task) * 60;
    setRemaining(total);
    setIsRunning(true);
    setMessage(focusMessages[Math.floor(Math.random() * focusMessages.length)]);
    return undefined;
  }, [visible, task]);

  useEffect(() => {
    if (!visible || !task || !isRunning) return undefined;
    intervalRef.current = setInterval(() => {
      setRemaining((value) => {
        if (value <= 1) {
          clearInterval(intervalRef.current);
          onComplete(task.id);
          return 0;
        }
        return value - 1;
      });
    }, 1000);
    return () => clearInterval(intervalRef.current);
  }, [visible, task, isRunning, onComplete]);

  if (!visible || !task) return null;

  const progress = 1 - remaining / Math.max(taskDurationMinutes(task) * 60, 1);
  const minutes = String(Math.floor(remaining / 60)).padStart(2, '0');
  const seconds = String(remaining % 60).padStart(2, '0');

  return (
    <Modal visible={visible} animationType="slide">
      <SafeAreaView style={styles.focusRoot}>
        <View style={styles.focusHeader}>
          <Pressable onPress={() => {
            Alert.alert('Leave focus mode?', 'This session is meant to protect momentum. Leave only if you need to stop.', [
              { text: 'Stay', style: 'cancel' },
              { text: 'Leave', style: 'destructive', onPress: onClose },
            ]);
          }}>
            <Text style={styles.focusClose}>Close</Text>
          </Pressable>
        </View>
        <View style={styles.focusBody}>
          <Text style={styles.focusLabel}>Focus Mode</Text>
          <Text style={styles.focusMessage}>{message}</Text>
          <View style={styles.focusCircle}>
            <View style={[styles.focusProgress, { width: `${Math.max(0, Math.min(progress, 1)) * 100}%` }]} />
            <Text style={styles.focusTime}>{`${minutes}:${seconds}`}</Text>
            <Text style={styles.focusTimeCaption}>Remaining</Text>
          </View>
          <Text style={styles.focusTaskTitle}>{task.title}</Text>
          <Text style={styles.focusTaskText}>{task.description || `${taskDurationMinutes(task)} min session`}</Text>
        </View>
        <View style={styles.focusActions}>
          <Pressable onPress={() => setIsRunning((value) => !value)} style={[styles.actionButton, styles.focusPrimaryButton]}>
            <Text style={styles.focusPrimaryButtonText}>{isRunning ? 'Pause Session' : 'Resume Session'}</Text>
          </Pressable>
          <Pressable onPress={() => onComplete(task.id)} style={[styles.actionButton, styles.focusSecondaryButton]}>
            <Text style={styles.focusSecondaryButtonText}>Mark Complete</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    </Modal>
  );
}

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [activeTab, setActiveTab] = useState('Home');
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('Today');
  const [loading, setLoading] = useState(true);
  const [onboardingVisible, setOnboardingVisible] = useState(false);
  const [editorVisible, setEditorVisible] = useState(false);
  const [editingTask, setEditingTask] = useState(null);
  const [focusTask, setFocusTask] = useState(null);

  useEffect(() => {
    (async () => {
      try {
        const [storedTasks, onboarding] = await Promise.all([
          AsyncStorage.getItem(STORAGE_KEY),
          AsyncStorage.getItem(ONBOARDING_KEY),
        ]);
        const parsedTasks = storedTasks ? JSON.parse(storedTasks) : buildSeedTasks();
        setTasks(sortTasks(parsedTasks));
        if (!storedTasks) {
          await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(parsedTasks));
        }
        setOnboardingVisible(onboarding !== 'done');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const persistTasks = async (nextTasks) => {
    const sorted = sortTasks(nextTasks);
    setTasks(sorted);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(sorted));
  };

  const now = new Date();
  const todayTasks = tasks.filter((task) => isSameDay(new Date(task.date), now));
  const tomorrowTasks = tasks.filter((task) => isTomorrow(new Date(task.date), now));
  const nextFocusTask = todayTasks.find((task) => !task.isCompleted) ?? null;
  const todayRate = completionRateFor(tasks, now);
  const weekStats = weeklyData(tasks);
  const weekAverage = weekStats.length ? weekStats.reduce((sum, item) => sum + item.completionRate, 0) / weekStats.length : 0;
  const filteredTasks = useMemo(() => {
    const source = tasks.filter((task) => {
      const date = new Date(task.date);
      if (filter === 'Today') return isSameDay(date, now);
      if (filter === 'Tomorrow') return isTomorrow(date, now);
      return taskInCurrentWeek(date, now);
    });
    const q = search.trim().toLowerCase();
    if (!q) return source;
    return source.filter((task) => `${task.title} ${task.description}`.toLowerCase().includes(q));
  }, [tasks, filter, search]);

  const completedWeek = tasks.filter((task) => taskInCurrentWeek(new Date(task.date), now) && task.isCompleted).length;
  const bestDay = [...weekStats].sort((a, b) => b.completionRate - a.completionRate)[0];

  const openNewTask = (targetDate) => {
    setEditingTask(targetDate ? { date: targetDate.toISOString() } : null);
    setEditorVisible(true);
  };

  const saveTask = async (task) => {
    const exists = tasks.some((item) => item.id === task.id);
    const nextTasks = exists ? tasks.map((item) => (item.id === task.id ? task : item)) : [...tasks, task];
    await persistTasks(nextTasks);
    setEditorVisible(false);
    setEditingTask(null);
  };

  const toggleTask = async (id) => {
    await persistTasks(tasks.map((task) => (task.id === id ? { ...task, isCompleted: !task.isCompleted } : task)));
  };

  const deleteTask = async (id) => {
    await persistTasks(tasks.filter((task) => task.id !== id));
  };

  const completeTask = async (id) => {
    await persistTasks(tasks.map((task) => (task.id === id ? { ...task, isCompleted: true } : task)));
    setFocusTask(null);
  };

  const resetData = async () => {
    const seed = buildSeedTasks();
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(seed));
    await AsyncStorage.removeItem(ONBOARDING_KEY);
    setTasks(sortTasks(seed));
    setOnboardingVisible(true);
  };

  const dismissOnboarding = async () => {
    await AsyncStorage.setItem(ONBOARDING_KEY, 'done');
    setOnboardingVisible(false);
  };

  const renderTaskRow = (task) => (
    <TaskRow
      key={task.id}
      task={task}
      onToggle={() => toggleTask(task.id)}
      onEdit={() => {
        setEditingTask(task);
        setEditorVisible(true);
      }}
      onDelete={() => deleteTask(task.id)}
      onFocus={() => setFocusTask(task)}
    />
  );

  const renderHome = () => (
    <>
      <Card>
        <Text style={styles.heroTitle}>{greeting()}</Text>
        <Text style={styles.heroSub}>{`${todayTasks.filter((task) => task.isCompleted).length} of ${todayTasks.length} tasks complete`}</Text>
        <View style={styles.heroRateRow}>
          <ProgressBar progress={todayRate} />
          <Text style={styles.heroRateText}>{`${Math.round(todayRate * 100)}%`}</Text>
        </View>
      </Card>
      <View style={styles.metricsRow}>
        <MetricCard title="Streak" value={`${currentStreak(tasks)}d`} caption="Days with full completion" />
        <MetricCard title="Weekly Avg" value={`${Math.round(weekAverage * 100)}%`} caption="Average completion rate" />
      </View>
      <Card>
        <Text style={styles.sectionCardTitle}>Focus recommendation</Text>
        {nextFocusTask ? (
          <>
            <Text style={styles.sectionCardHeadline}>{nextFocusTask.title}</Text>
            <Text style={styles.sectionCardMeta}>{`${formatTime(nextFocusTask.startMinutes)} - ${formatTime(nextFocusTask.endMinutes)} • ${taskDurationMinutes(nextFocusTask)} min`}</Text>
            <Pressable style={styles.primaryButton} onPress={() => setFocusTask(nextFocusTask)}>
              <Text style={styles.primaryButtonText}>Start Focus</Text>
            </Pressable>
          </>
        ) : (
          <Text style={styles.sectionCardMeta}>Your next focus block appears here when there is an unfinished task scheduled for today.</Text>
        )}
      </Card>
      <SectionHeader title="Tomorrow Planner" actionLabel="Add" onPress={() => openNewTask(new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1))} />
      {tomorrowTasks.length ? tomorrowTasks.slice(0, 2).map(renderTaskRow) : <EmptyState title="Nothing planned for tomorrow" subtitle="Set tomorrow's most important tasks while context is still fresh." />}
      <SectionHeader title="Today's Tasks" actionLabel="Add" onPress={() => openNewTask()} />
      {todayTasks.length ? todayTasks.slice(0, 4).map(renderTaskRow) : <EmptyState title="No tasks for today" subtitle="Create a realistic plan with clear start and end times." />}
    </>
  );

  const renderTasks = () => (
    <>
      <TextInput value={search} onChangeText={setSearch} placeholder="Search tasks" style={styles.input} placeholderTextColor={theme.muted} />
      <View style={styles.chipRow}>{['Today', 'Tomorrow', 'This Week'].map((item) => <Chip key={item} label={item} active={filter === item} onPress={() => setFilter(item)} />)}</View>
      {filteredTasks.length ? filteredTasks.map(renderTaskRow) : <EmptyState title="No tasks found" subtitle="Try another filter or create a new task." />}
    </>
  );

  const renderStats = () => (
    <>
      <Card>
        <Text style={styles.sectionCardHeadline}>Performance overview</Text>
        <Text style={styles.sectionCardMeta}>Use your weekly trend to decide whether your plans are realistic or overloaded.</Text>
      </Card>
      <Card>
        <Text style={styles.sectionCardTitle}>Last 7 days</Text>
        <View style={styles.chartRow}>
          {weekStats.map((item) => (
            <View key={item.label} style={styles.chartItem}>
              <View style={[styles.chartBar, { height: 24 + item.completionRate * 140 }]} />
              <Text style={styles.chartLabel}>{item.label}</Text>
            </View>
          ))}
        </View>
      </Card>
      <MetricCard title="Today" value={`${Math.round(todayRate * 100)}%`} caption="Completion rate today" />
      <MetricCard title="Completed this week" value={String(completedWeek)} caption="Finished tasks in the current week" />
      <MetricCard title="Current streak" value={`${currentStreak(tasks)} days`} caption={bestDay ? `Best day: ${bestDay.label}` : 'Start with today\'s plan'} />
    </>
  );

  const renderSettings = () => (
    <>
      <Card>
        <Text style={styles.sectionCardHeadline}>About Planios</Text>
        <Text style={styles.sectionCardMeta}>Planios is a green, minimal productivity app built around realistic planning, focused execution, and visible progress.</Text>
        <View style={styles.listBlock}>
          <Text style={styles.listLine}>• Daily, tomorrow, and weekly task planning</Text>
          <Text style={styles.listLine}>• Focus mode with countdown and guarded exit</Text>
          <Text style={styles.listLine}>• Weekly completion analytics and streak tracking</Text>
          <Text style={styles.listLine}>• Local-first persistence through AsyncStorage</Text>
        </View>
      </Card>
      <Card>
        <Text style={styles.sectionCardHeadline}>Data</Text>
        <Text style={styles.sectionCardMeta}>{`${tasks.length} tasks currently stored on this device.`}</Text>
        <Pressable
          style={[styles.secondaryButton, { marginTop: 16 }]}
          onPress={() => Alert.alert('Reset app data?', 'This clears tasks and onboarding state on the current device.', [
            { text: 'Cancel', style: 'cancel' },
            { text: 'Reset', style: 'destructive', onPress: resetData },
          ])}
        >
          <Text style={styles.secondaryButtonText}>Reset demo data</Text>
        </Pressable>
      </Card>
    </>
  );

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar style="dark" />
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{activeTab === 'Home' ? 'Planios' : activeTab}</Text>
        <Pressable style={styles.headerAddButton} onPress={() => openNewTask()}>
          <Text style={styles.headerAddButtonText}>+</Text>
        </Pressable>
      </View>
      {loading ? (
        <View style={styles.loadingWrap}><Text style={styles.loadingText}>Loading...</Text></View>
      ) : (
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          {activeTab === 'Home' && renderHome()}
          {activeTab === 'Tasks' && renderTasks()}
          {activeTab === 'Stats' && renderStats()}
          {activeTab === 'Settings' && renderSettings()}
        </ScrollView>
      )}
      <View style={styles.tabBar}>
        {tabs.map((tab) => (
          <Pressable key={tab} onPress={() => setActiveTab(tab)} style={styles.tabButton}>
            <Text style={[styles.tabText, activeTab === tab && styles.tabTextActive]}>{tab}</Text>
          </Pressable>
        ))}
      </View>
      {onboardingVisible && (
        <Modal visible transparent animationType="fade">
          <View style={styles.modalBackdrop}>
            <View style={styles.onboardingCard}>
              <Text style={styles.modalTitle}>Welcome to Planios</Text>
              <Text style={styles.sectionCardMeta}>Plan your day, protect focus, and track consistency from a clean Expo app built for Android emulators and real devices.</Text>
              <View style={styles.listBlock}>
                <Text style={styles.listLine}>• Daily and weekly planning</Text>
                <Text style={styles.listLine}>• Focus sessions with countdown timer</Text>
                <Text style={styles.listLine}>• Local-first task storage</Text>
                <Text style={styles.listLine}>• Completion statistics and streaks</Text>
              </View>
              <Pressable style={styles.primaryButton} onPress={dismissOnboarding}>
                <Text style={styles.primaryButtonText}>Start Planning</Text>
              </Pressable>
            </View>
          </View>
        </Modal>
      )}
      <TaskEditor visible={editorVisible} task={editingTask} onClose={() => { setEditorVisible(false); setEditingTask(null); }} onSave={saveTask} />
      <FocusModal visible={!!focusTask} task={focusTask} onClose={() => setFocusTask(null)} onComplete={completeTask} />
    </SafeAreaView>
  );
}

function EmptyState({ title, subtitle }) {
  return (
    <Card>
      <Text style={styles.sectionCardHeadline}>{title}</Text>
      <Text style={styles.sectionCardMeta}>{subtitle}</Text>
    </Card>
  );
}

function SectionHeader({ title, actionLabel, onPress }) {
  return (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <Pressable onPress={onPress}><Text style={styles.sectionAction}>{actionLabel}</Text></Pressable>
    </View>
  );
}

function greeting() {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 22) return 'Good evening';
  return 'Reset the day';
}
const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: theme.bg },
  header: { paddingHorizontal: 20, paddingTop: 8, paddingBottom: 12, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  headerTitle: { fontSize: 28, fontWeight: '800', color: theme.text },
  headerAddButton: { width: 42, height: 42, borderRadius: 21, backgroundColor: theme.green, alignItems: 'center', justifyContent: 'center' },
  headerAddButtonText: { color: '#fff', fontSize: 24, lineHeight: 24 },
  content: { paddingHorizontal: 20, paddingBottom: 120 },
  loadingWrap: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  loadingText: { color: theme.text, fontSize: 16 },
  card: { backgroundColor: theme.card, borderRadius: 28, padding: 20, marginBottom: 14 },
  heroTitle: { fontSize: 30, fontWeight: '800', color: theme.text },
  heroSub: { color: theme.muted, marginTop: 6, marginBottom: 16, fontSize: 15 },
  heroRateRow: { gap: 12 },
  heroRateText: { color: theme.greenDark, fontWeight: '700', fontSize: 14, marginTop: 8 },
  progressTrack: { width: '100%', height: 12, backgroundColor: '#E4EEE9', borderRadius: 999, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 999, backgroundColor: theme.green },
  metricsRow: { flexDirection: 'row', gap: 12, marginBottom: 14 },
  metricCard: { flex: 1, marginBottom: 0 },
  metricTitle: { color: theme.muted, fontWeight: '700' },
  metricValue: { marginTop: 10, fontSize: 28, fontWeight: '800', color: theme.text },
  metricCaption: { marginTop: 6, color: theme.muted, fontSize: 13, lineHeight: 18 },
  sectionHeader: { marginTop: 4, marginBottom: 8, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  sectionTitle: { fontSize: 22, fontWeight: '800', color: theme.text },
  sectionAction: { color: theme.green, fontWeight: '700', fontSize: 15 },
  sectionCardTitle: { color: theme.green, fontWeight: '700', fontSize: 15, marginBottom: 10 },
  sectionCardHeadline: { fontSize: 22, fontWeight: '800', color: theme.text },
  sectionCardMeta: { marginTop: 8, color: theme.muted, fontSize: 14, lineHeight: 20 },
  primaryButton: { marginTop: 16, backgroundColor: theme.green, borderRadius: 18, paddingVertical: 14, alignItems: 'center' },
  primaryButtonText: { color: '#fff', fontWeight: '700', fontSize: 15 },
  secondaryButton: { backgroundColor: '#EEF3F0', borderRadius: 18, paddingVertical: 14, paddingHorizontal: 16, alignItems: 'center' },
  secondaryButtonText: { color: theme.text, fontWeight: '700', fontSize: 15 },
  taskCard: { paddingBottom: 16 },
  taskTop: { flexDirection: 'row', gap: 12 },
  checkbox: { width: 28, height: 28, marginTop: 3, borderWidth: 2, borderColor: theme.border, borderRadius: 8, alignItems: 'center', justifyContent: 'center' },
  checkboxChecked: { backgroundColor: theme.green, borderColor: theme.green },
  checkboxMark: { color: '#fff', fontWeight: '800' },
  taskMain: { flex: 1 },
  taskTitle: { color: theme.text, fontSize: 18, fontWeight: '700' },
  taskTitleDone: { textDecorationLine: 'line-through', opacity: 0.65 },
  taskMeta: { marginTop: 4, color: theme.muted, fontSize: 13 },
  taskDescription: { marginTop: 8, color: theme.text, fontSize: 14, lineHeight: 20 },
  taskFooter: { marginTop: 14, gap: 12 },
  tagRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  tag: { backgroundColor: theme.bg, color: theme.text, paddingHorizontal: 10, paddingVertical: 6, borderRadius: 999, overflow: 'hidden', fontSize: 12, fontWeight: '700' },
  inlineActions: { flexDirection: 'row', gap: 10 },
  inlineButton: { backgroundColor: '#EEF3F0', borderRadius: 14, paddingHorizontal: 14, paddingVertical: 10 },
  inlineButtonText: { color: theme.text, fontWeight: '700' },
  inlineButtonDanger: { backgroundColor: '#FBEAEA' },
  inlineButtonDangerText: { color: theme.danger, fontWeight: '700' },
  input: { backgroundColor: '#fff', borderRadius: 18, paddingHorizontal: 16, paddingVertical: 14, color: theme.text, marginBottom: 12, borderWidth: 1, borderColor: theme.border },
  textArea: { minHeight: 100, textAlignVertical: 'top' },
  doubleRow: { flexDirection: 'row', gap: 12 },
  halfInput: { flex: 1 },
  fieldLabel: { marginTop: 4, marginBottom: 10, color: theme.text, fontWeight: '700' },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 },
  chip: { paddingHorizontal: 14, paddingVertical: 10, borderRadius: 999, backgroundColor: '#EEF3F0' },
  chipActive: { backgroundColor: theme.green },
  chipText: { color: theme.text, fontWeight: '700' },
  chipTextActive: { color: '#fff' },
  switchRow: { marginTop: 4, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  switchLabel: { color: theme.text, fontWeight: '700', fontSize: 15 },
  modalBackdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.45)', justifyContent: 'flex-end' },
  modalSheet: { maxHeight: '88%', backgroundColor: theme.bg, borderTopLeftRadius: 28, borderTopRightRadius: 28, padding: 20 },
  modalTitle: { color: theme.text, fontSize: 24, fontWeight: '800', marginBottom: 16 },
  modalActions: { flexDirection: 'row', gap: 10, marginTop: 12 },
  actionButton: { flex: 1, backgroundColor: theme.green, borderRadius: 18, paddingVertical: 14, alignItems: 'center' },
  actionButtonText: { color: '#fff', fontWeight: '700', fontSize: 15 },
  tabBar: { position: 'absolute', left: 16, right: 16, bottom: 16, backgroundColor: '#fff', borderRadius: 24, paddingVertical: 12, flexDirection: 'row', justifyContent: 'space-around', borderWidth: 1, borderColor: theme.border },
  tabButton: { paddingHorizontal: 10, paddingVertical: 4 },
  tabText: { color: theme.muted, fontWeight: '700' },
  tabTextActive: { color: theme.green },
  chartRow: { marginTop: 18, flexDirection: 'row', alignItems: 'flex-end', height: 220, gap: 8 },
  chartItem: { flex: 1, alignItems: 'center', justifyContent: 'flex-end' },
  chartBar: { width: '100%', backgroundColor: theme.green, borderRadius: 14 },
  chartLabel: { marginTop: 8, color: theme.muted, fontSize: 12, fontWeight: '700' },
  listBlock: { marginTop: 16, gap: 8 },
  listLine: { color: theme.text, lineHeight: 20 },
  onboardingCard: { margin: 20, backgroundColor: theme.card, borderRadius: 28, padding: 24 },
  focusRoot: { flex: 1, backgroundColor: theme.greenDark },
  focusHeader: { paddingHorizontal: 20, paddingTop: 8, alignItems: 'flex-end' },
  focusClose: { color: '#fff', fontWeight: '700', fontSize: 16 },
  focusBody: { flex: 1, paddingHorizontal: 24, alignItems: 'center', justifyContent: 'center' },
  focusLabel: { color: 'rgba(255,255,255,0.88)', fontWeight: '700', fontSize: 18 },
  focusMessage: { marginTop: 12, color: 'rgba(255,255,255,0.78)', textAlign: 'center', fontSize: 16, lineHeight: 24 },
  focusCircle: { width: 250, height: 250, borderRadius: 125, marginTop: 28, marginBottom: 28, backgroundColor: 'rgba(255,255,255,0.12)', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  focusProgress: { position: 'absolute', left: 0, bottom: 0, top: 0, backgroundColor: 'rgba(140,224,187,0.38)' },
  focusTime: { color: '#fff', fontSize: 48, fontWeight: '800' },
  focusTimeCaption: { color: 'rgba(255,255,255,0.72)', marginTop: 8 },
  focusTaskTitle: { color: '#fff', fontSize: 28, fontWeight: '800', textAlign: 'center' },
  focusTaskText: { marginTop: 10, color: 'rgba(255,255,255,0.76)', fontSize: 15, textAlign: 'center', lineHeight: 22 },
  focusActions: { paddingHorizontal: 24, paddingBottom: 24, gap: 12 },
  focusPrimaryButton: { backgroundColor: '#fff' },
  focusPrimaryButtonText: { color: theme.greenDark, fontWeight: '800', fontSize: 15 },
  focusSecondaryButton: { backgroundColor: 'rgba(255,255,255,0.12)', borderWidth: 1, borderColor: 'rgba(255,255,255,0.18)' },
  focusSecondaryButtonText: { color: '#fff', fontWeight: '700', fontSize: 15 },
});