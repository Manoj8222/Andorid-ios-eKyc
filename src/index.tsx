// import { NativeModules, Platform, NativeEventEmitter } from 'react-native';

// const LINKING_ERROR =
//   `The package 'react-native-inno' doesn't seem to be linked. Make sure: \n\n` +
//   Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
//   '- You rebuilt the app after installing the package\n' +
//   '- You are not using Expo Go\n';

// const LINKING_ERROR1 =
//   `The package 'react-native-inno' doesn't seem to be linked. Make sure: \n\n` +
//   Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
//   '- You rebuilt the app after installing the package\n' +
//   '- You are not using Expo Go\n';

// // if(Platform.OS === 'android'){
// const SelectionActivity = NativeModules.SelectionActivity
//   ? NativeModules.SelectionActivity
//   : new Proxy(
//       {},
//       {
//         get() {
//           throw new Error(LINKING_ERROR);
//         },
//       }
//     );
// // }
// // if(Platform.OS === 'ios'){
//  const Inno = NativeModules.Inno
//   ? NativeModules.Inno
//   : new Proxy(
//       {},
//       {
//         get() {
//           throw new Error(LINKING_ERROR1);
//         },
//       }
//     );
//   // }
//   // const innoEmitter = Platform.OS === 'ios' ? new NativeEventEmitter(Inno) : null;

//   // if(Platform.OS === 'ios'){
//     const innoEmitter = new NativeEventEmitter(Inno);
//   // }

// // ✅ Show EKYC UI (Existing)
// export function showEkycUI(): Promise<void> {
//   return Inno.showEkycUI();
// }

// // ✅ Start Liveliness Detection & Receive `referenceID`
// export function startLivelinessDetection(
//   callback: (referenceID: string) => void
// ) {
//   const subscription = innoEmitter.addListener(
//     'onReferenceIDReceived',
//     (referenceID: string) => {
//       console.log('✅ Received Reference ID from iOS:', referenceID);
//       callback(referenceID);
//     }
//   );

//   Inno.startLivelinessDetection();

//   return () => {
//     subscription.remove(); // Cleanup listener when not needed
//   };
// }

// export function openSelectionScreen(): Promise<boolean> {
//   return SelectionActivity.openSelectionUI();
// }

import { NativeModules, Platform, NativeEventEmitter } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-inno' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// Platform-Specific Module Initialization
const SelectionActivity =
  Platform.OS === 'android'
    ? NativeModules.SelectionActivity ||
      new Proxy(
        {},
        {
          get() {
            throw new Error(LINKING_ERROR);
          },
        }
      )
    : null;

const Inno =
  Platform.OS === 'ios'
    ? NativeModules.Inno ||
      new Proxy(
        {},
        {
          get() {
            throw new Error(LINKING_ERROR);
          },
        }
      )
    : null;

const innoEmitter =
  Platform.OS === 'ios' && Inno ? new NativeEventEmitter(Inno) : null;

// iOS-Specific Functions
export function showEkycUI(): Promise<void> {
  if (Platform.OS !== 'ios') {
    return Promise.reject('showEkycUI is only available on iOS');
  }
  return Inno.showEkycUI();
}

export function startLivelinessDetection(
  callback: (referenceID: string) => void
) {
  if (Platform.OS !== 'ios') {
    throw new Error('startLivelinessDetection is only available on iOS');
  }
  if (!innoEmitter) {
    throw new Error('NativeEventEmitter not initialized');
  }

  const subscription = innoEmitter.addListener(
    'onReferenceIDReceived',
    (referenceID: string) => {
      console.log('Received Reference ID:', referenceID);
      callback(referenceID);
    }
  );

  Inno.startLivelinessDetection();

  return () => subscription.remove();
}

// Android-Specific Function
export function openSelectionScreen(): Promise<boolean> {
  if (Platform.OS !== 'android') {
    return Promise.reject('openSelectionScreen is only available on Android');
  }
  return SelectionActivity.openSelectionUI();
}
