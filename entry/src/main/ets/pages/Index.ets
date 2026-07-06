import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode } from '@kit.ArkUI';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../constants/Constants';
import { LANDMARKS, ALL_LANDMARKS_BOUNDS, Landmark } from '../model/LandmarkData';

const TAG: string = 'CameraZoom';

@Entry
@Component
struct Index {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private crownAccumulator: number = 0;
  @State private selectedKey: string = '';
  @State private toastText: string = '';
  @State private toastVisible: boolean = false;
  private toastTimer: number = -1;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: { latitude: 45.0, longitude: 13.0 },
        zoom: Constants.INITIAL_ZOOM
      }
    };

    this.callback = async (err, mapController) => {
      if (err) {
        hilog.error(0x0000, TAG, `Map init failed: ${err.code} ${err.message}`);
        return;
      }
      this.mapController = mapController;
      hilog.info(0x0000, TAG, 'MapComponentController ready');
    };
  }

  aboutToDisappear(): void {
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer);
    }
  }

  private landmarkKey(lm: Landmark): string {
    return `${lm.latLng.latitude}_${lm.latLng.longitude}`;
  }

  /**
   * Runs animateCameraStatus(), shows the AnimateResult status as a brief toast.
   * AnimateResult.isFinished indicates whether the camera animation completed
   * successfully (true) or was interrupted/cancelled (false).
   */
  private async animateAndShowResult(update: map.CameraUpdate, duration: number): Promise<void> {
    if (!this.mapController) {
      return;
    }
    try {
      const result: map.AnimateResult =
        await this.mapController.animateCameraStatus(update, duration);
      hilog.info(0x0000, TAG, `AnimateResult: ${JSON.stringify(result)}`);
      this.showToast(result.isFinished ? 'Finished' : 'Cancelled');
    } catch (e) {
      hilog.error(0x0000, TAG, `animateCameraStatus error: ${e.code} ${e.message}`);
    }
  }

  private showToast(msg: string): void {
    this.toastText = msg;
    this.toastVisible = true;
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer);
    }
    this.toastTimer = setTimeout(() => {
      this.toastVisible = false;
      this.toastTimer = -1;
    }, Constants.TOAST_DURATION_MS) as number;
  }

  private handleCrown(event: CrownEvent): void {
    event.stopPropagation();

    if (event.action === CrownAction.END) {
      this.crownAccumulator = 0;
      return;
    }

    this.crownAccumulator += event.degree;

    if (this.crownAccumulator >= Constants.CROWN_ZOOM_THRESHOLD_DEG) {
      this.crownAccumulator = 0;
      if (this.mapController) {
        this.mapController.animateCamera(map.zoomIn(), Constants.CROWN_ANIMATE_DURATION_MS);
      }
    } else if (this.crownAccumulator <= -Constants.CROWN_ZOOM_THRESHOLD_DEG) {
      this.crownAccumulator = 0;
      if (this.mapController) {
        this.mapController.animateCamera(map.zoomOut(), Constants.CROWN_ANIMATE_DURATION_MS);
      }
    }
  }

  /** Landmark chip tap → newCameraPosition(). */
  private flyToLandmark(lm: Landmark): void {
    this.selectedKey = this.landmarkKey(lm);

    const cameraPosition: mapCommon.CameraPosition = {
      target: lm.latLng,
      zoom: lm.zoom,
      tilt: lm.tilt,
      bearing: lm.bearing
    };
    const update: map.CameraUpdate = map.newCameraPosition(cameraPosition);
    this.animateAndShowResult(update, Constants.ANIMATE_DURATION_MS);
  }

  /** "Fit All" → newLatLngBounds(). */
  private fitAllLandmarks(): void {
    const update: map.CameraUpdate =
      map.newLatLngBounds(ALL_LANDMARKS_BOUNDS, Constants.FIT_ALL_PADDING_PX);
    this.animateAndShowResult(update, Constants.ANIMATE_DURATION_MS);
  }

  /** "×2" → zoomBy() with screen-centre focus. */
  private zoomByDouble(): void {
    const focus: mapCommon.MapPoint = { positionX: 233, positionY: 233 };
    const update: map.CameraUpdate = map.zoomBy(Constants.ZOOM_BY_AMOUNT, focus);
    this.animateAndShowResult(update, Constants.ANIMATE_DURATION_MS);
  }

  /** "Z14" → zoomTo(). */
  private zoomToLevel(): void {
    const update: map.CameraUpdate = map.zoomTo(Constants.ZOOM_TO_LEVEL);
    this.animateAndShowResult(update, Constants.ANIMATE_DURATION_MS);
  }

  /** Pan arrow → scrollBy(). */
  private panMap(dx: number, dy: number): void {
    const update: map.CameraUpdate = map.scrollBy(dx, dy);
    this.mapController?.animateCamera(update, Constants.CROWN_ANIMATE_DURATION_MS);
  }

  build() {
    RelativeContainer() {

      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback
        })
          .width('100%')
          .height('100%')
      }
      .width('100%')
      .height('100%')
      .focusable(true)
      .defaultFocus(true)
      .focusOnTouch(true)
      .onDigitalCrown((event: CrownEvent) => {
        this.handleCrown(event);
      })
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .id('mapContainer')
      Row({ space: 4 }) {
        ForEach(LANDMARKS, (lm: Landmark) => {
          Text(lm.nameKey)
            .fontSize(10)
            .fontColor(this.landmarkKey(lm) === this.selectedKey
              ? $r('app.color.chip_text_active')
              : $r('app.color.chip_text_inactive'))
            .backgroundColor(this.landmarkKey(lm) === this.selectedKey
              ? $r('app.color.chip_bg_active')
              : $r('app.color.chip_bg_inactive'))
            .borderRadius(10)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .onClick(() => this.flyToLandmark(lm))
        }, (lm: Landmark) => this.landmarkKey(lm))
      }
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .margin({ top: 10 })
      .id('chipRow')

      // Pan arrows
      Column({ space: 1 }) {
        Button($r('app.string.arrow_up'))
          .fontSize(11).type(ButtonType.Circle)
          .width(24).height(24)
          .fontColor($r('app.color.btn_text'))
          .backgroundColor($r('app.color.btn_bg'))
          .onClick(() => this.panMap(0, -Constants.SCROLL_OFFSET_PX))

        Row({ space: 1 }) {
          Button($r('app.string.arrow_left'))
            .fontSize(11).type(ButtonType.Circle)
            .width(24).height(24)
            .fontColor($r('app.color.btn_text'))
            .backgroundColor($r('app.color.btn_bg'))
            .onClick(() => this.panMap(-Constants.SCROLL_OFFSET_PX, 0))

          Button($r('app.string.arrow_right'))
            .fontSize(11).type(ButtonType.Circle)
            .width(24).height(24)
            .fontColor($r('app.color.btn_text'))
            .backgroundColor($r('app.color.btn_bg'))
            .onClick(() => this.panMap(Constants.SCROLL_OFFSET_PX, 0))
        }

        Button($r('app.string.arrow_down'))
          .fontSize(11).type(ButtonType.Circle)
          .width(24).height(24)
          .fontColor($r('app.color.btn_text'))
          .backgroundColor($r('app.color.btn_bg'))
          .onClick(() => this.panMap(0, Constants.SCROLL_OFFSET_PX))
      }
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .margin({ left: 4, top: 30 })
      .id('panControls')

      //  Zoom buttons
      Column({ space: 4 }) {
        Button($r('app.string.btn_zoom_by'))
          .fontSize(12)
          .fontColor($r('app.color.btn_text'))
          .backgroundColor($r('app.color.btn_bg'))
          .width(56).height(26)
          .borderRadius(8)
          .onClick(() => this.zoomByDouble())

        Button($r('app.string.btn_zoom_to'))
          .fontSize(12)
          .fontColor($r('app.color.btn_text'))
          .backgroundColor($r('app.color.btn_bg'))
          .width(56).height(26)
          .borderRadius(8)
          .onClick(() => this.zoomToLevel())
      }
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })
      .margin({ right: 4, top: 30 })
      .id('zoomControls')

      if (this.toastVisible) {
        Text(this.toastText)
          .fontSize(12)
          .fontColor($r('app.color.toast_text'))
          .backgroundColor($r('app.color.toast_bg'))
          .borderRadius(12)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .id('toast')
      }

      ArcButton({
        options: new ArcButtonOptions({
          label: $r('app.string.btn_fit_all'),
          position: ArcButtonPosition.BOTTOM_EDGE,
          styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
          onClick: () => {
            this.fitAllLandmarks();
          }
        })
      })
        .id('arcBtnFitAll')
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })

    }
    .width('100%')
    .height('100%')
  }
}
