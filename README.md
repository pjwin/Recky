# Recky

## Recommendation Module Structure

The recommendation feature follows a simple layered layout to keep responsibilities clear.

- `Recommendation/Models` – data structures and domain types such as `Recommendation` and its associated tags.
- `Recommendation/ViewModels` – SwiftUI view models that prepare data for display (`RecommendationListViewModel`, `RecommendationDetailViewModel`).
- `Recommendation/Repositories` – services and data sources used to load or persist recommendations (`RecommendationRepository`, `RecommendationService`, `RecommendationStatsService`).
- `Recommendation/Views` – SwiftUI views that present recommendations to the user (`RecommendationListView`, `RecommendationCardView`, etc.).

When adding new code, place files in the folder that matches their role. Avoid leaving files directly inside `Recommendation`; keeping the structure consistent makes the project easier to navigate for new contributors.

