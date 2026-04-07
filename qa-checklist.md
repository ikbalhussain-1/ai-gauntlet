# QA Checklist — Review Intelligence

## Screen 1: Upload Screen

1. Upload zone is visible and centred on page load
2. Instruction text "Upload your weekly reviews CSV to get instant insights" is present
3. "Analyse Reviews" button is **disabled** when no file is selected
4. Clicking the upload zone opens a file picker dialog
5. Only CSV files are accepted (non-CSV files show an error message)
6. After selecting a CSV, the filename is displayed in the upload zone
7. After selecting a CSV, the "Analyse Reviews" button becomes **enabled**
8. Clicking "Analyse Reviews" shows a progress/loading indicator
9. While analysis is running, the button is disabled (prevents double-submit)
10. On success, the user is navigated to the Dashboard screen
11. If the API returns an error, a user-friendly error message is displayed
12. The upload zone accepts drag-and-drop of a CSV file

## Screen 2: Analysis Dashboard

13. The page header shows app name "Review Intelligence"
14. Total Reviews summary card shows the correct count (e.g. 30)
15. Positive Sentiment % card shows a percentage value
16. Most Common Theme card shows a valid theme name
17. Theme Distribution bar chart is visible with at least one bar
18. Bar chart labels show theme names on the axis
19. Sentiment Breakdown donut/pie chart is visible with 3 segments (Positive, Negative, Neutral)
20. Donut chart has a legend showing Positive / Negative / Neutral
21. Reviews table is visible with columns: Product, Review Text, Theme, Sentiment, Key Phrases
22. Review text is truncated to a readable length (not full paragraph)
23. Theme column shows a coloured badge
24. Sentiment column shows an icon or badge (Positive/Negative/Neutral)
25. Filter dropdown for Theme is present and functional
26. Filter dropdown for Sentiment is present and functional
27. Text search box is present and filters the table in real time
28. Selecting a Theme filter shows only reviews with that theme
29. Selecting a Sentiment filter shows only reviews with that sentiment
30. Combining Theme + Sentiment filters works correctly
31. Clearing filters restores the full table
32. Clicking a theme in the bar chart navigates to Theme Detail view

## Screen 3: Theme Detail View

33. Back button is present and navigates back to the Dashboard
34. Page header shows the selected theme name
35. Review count for the theme is displayed
36. Sentiment distribution for that theme is shown (counts or %)
37. Full list of reviews for that theme is shown
38. Each review shows: product, review text, sentiment, key phrases
39. Theme Detail is accessible by clicking a theme bar in the chart

## General

40. Loading spinner is shown while API calls are in progress
41. Error state is shown with a clear message if the backend is unreachable
42. Page does not crash on empty results (0 reviews analysed)
43. App is usable at 1280×800 viewport width
