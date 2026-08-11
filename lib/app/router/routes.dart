/// Central route names and paths. Screens navigate by name so paths can
/// evolve without touching feature code.
abstract final class Routes {
  // Entry
  static const splash = 'splash';
  static const welcome = 'welcome';
  static const signIn = 'sign-in';
  static const register = 'register';
  static const forgotPassword = 'forgot-password';
  static const onboarding = 'onboarding';

  // Shell tabs
  static const map = 'map';
  static const discover = 'discover';
  static const create = 'create';
  static const notifications = 'notifications';
  static const profile = 'profile';

  // Detail routes
  static const restaurant = 'restaurant';
  static const taster = 'taster';
  static const list = 'list';
  static const listEdit = 'list-edit';
  static const createRecommendation = 'create-recommendation';
  static const editRecommendation = 'edit-recommendation';
  static const createList = 'create-list';
  static const search = 'search';
  static const biteswipe = 'biteswipe';
  static const feed = 'feed';
  static const savedRestaurants = 'saved';
  static const visitedRestaurants = 'visited';
  static const settings = 'settings';
  static const editProfile = 'edit-profile';
  static const premium = 'premium';
  static const messages = 'messages';
  static const chat = 'chat';
  static const tasteGroups = 'taste-groups';
  static const tasteGroup = 'taste-group';
  static const trips = 'trips';
  static const trip = 'trip';
  static const follows = 'follows';
}
