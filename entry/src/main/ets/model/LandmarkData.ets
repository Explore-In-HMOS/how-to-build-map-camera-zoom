import { mapCommon } from '@kit.MapKit';
import { Constants } from '../constants/Constants';

export interface Landmark {
  nameKey: Resource;
  latLng: mapCommon.LatLng;
  zoom: number;
  tilt: number;
  bearing: number;
}

export const LANDMARKS: Landmark[] = [
  {
    nameKey: $r('app.string.landmark_istanbul'),
    latLng: { latitude: 41.0086, longitude: 28.9802 },
    zoom: Constants.LANDMARK_ZOOM,
    tilt: Constants.LANDMARK_TILT,
    bearing: 30
  },
  {
    nameKey: $r('app.string.landmark_madrid'),
    latLng: { latitude: 40.4168, longitude: -3.7038 },
    zoom: Constants.LANDMARK_ZOOM,
    tilt: Constants.LANDMARK_TILT,
    bearing: 0
  },
  {
    nameKey: $r('app.string.landmark_berlin'),
    latLng: { latitude: 52.5163, longitude: 13.3777 },
    zoom: Constants.LANDMARK_ZOOM,
    tilt: Constants.LANDMARK_TILT,
    bearing: 315
  }
];

/**
 * LatLngBounds that encloses all three landmarks.
 * Used by newLatLngBounds() in the "Fit All" action.
 */
export const ALL_LANDMARKS_BOUNDS: mapCommon.LatLngBounds = {
  southwest: { latitude: 40.4168, longitude: -3.7038 },
  northeast: { latitude: 52.5163, longitude: 28.9802 }
};
