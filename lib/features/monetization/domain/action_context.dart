/// Where an outbound restaurant action came from, and what led the user to it.
///
/// This exists so attribution is captured at the call site, where it is
/// actually known. By the time a tap reaches the link opener, the fact that the
/// user got there from a particular Taster's recommendation inside a particular
/// list is gone unless it was carried along deliberately.
///
/// The questions this has to be able to answer later:
///   - which Taster's recommendation led to the click
///   - which list led to the click
///   - did the user arrive through BiteSwipe
///   - which city and which surface generated the action
library;

/// The screen the action was taken from. A closed set rather than free text,
/// because these become dashboard dimensions and typos are invisible bugs in
/// aggregate data.
enum ActionSource {
  map('map'),
  biteSwipe('taste_deck'),
  restaurantPage('restaurant_page'),
  tasterProfile('taster_profile'),
  recommendation('recommendation'),
  list('list'),
  discover('discover'),
  search('search'),
  cityPage('city_page'),
  notification('notification');

  const ActionSource(this.wire);

  /// Stored value. Kept stable even if the enum is renamed, because historical
  /// rows must stay comparable.
  final String wire;
}

/// What the user did. Mirrors restaurant_action_links.action_type plus the
/// non-link interactions worth attributing.
enum RestaurantAction {
  directions('directions'),
  website('website'),
  phone('phone'),
  menu('menu'),
  reservation('reservation'),
  orderDelivery('order_delivery'),
  orderPickup('order_pickup'),
  bookExperience('book_experience'),
  socialProfile('social_profile'),
  opened('restaurant_opened'),
  saved('restaurant_saved'),
  unsaved('restaurant_unsaved'),
  markedVisited('restaurant_marked_visited'),
  shared('restaurant_shared');

  const RestaurantAction(this.wire);
  final String wire;
}

/// Attribution carried alongside an action.
class ActionContext {
  const ActionContext({
    required this.source,
    this.sourceFeature,
    this.tasterId,
    this.recommendationId,
    this.listId,
    this.cityId,
  });

  final ActionSource source;

  /// Finer-grained origin within the screen, e.g. 'recommended_filter'.
  final String? sourceFeature;

  /// The Taster whose recommendation surfaced this restaurant, when known.
  final String? tasterId;
  final String? recommendationId;
  final String? listId;
  final String? cityId;
}
